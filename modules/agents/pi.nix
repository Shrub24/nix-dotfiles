{
  config,
  inputs,
  lib,
  ...
}:
let
  # Read at the flake-parts level and closed over by the HM module — the same
  # shape as omniroute/ntfy/niks3. The endpoint resolves from the fleet's
  # canonical inventory, never a literal in the extension's config.
  hindsightUrl = inputs.nix-fleet.lib.serviceEndpoints.url config.fleet {
    service = "hindsight";
    endpoint = "api";
    via = "tailnet";
  };
  # docs-mcp runs on home-forge, so its MCP endpoint comes from the fleet
  # inventory rather than from the port this repository's own module declares.
  docsMcpUrl = inputs.nix-fleet.lib.serviceEndpoints.url config.fleet {
    service = "docs-mcp";
    endpoint = "mcp";
    via = "tailnet";
  };
  # A build compiles the recipes of the rows that name it; the package carries
  # no selection of its own.
  compiledPlugins =
    registry: variant:
    lib.listToAttrs (
      map (row: lib.nameValuePair row.id registry.plugins.${row.id}) (
        lib.filter (row: lib.elem variant (row.compiled or [ ])) (import ./_pi-extensions.nix)
      )
    );
in
{
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    let
      # Use the same package overlay as the hosts.
      repoPkgs = pkgs.extend (import ../../pkgs { inherit inputs system; });
      registry = repoPkgs.pi-plugins;
      # The child build carries a whole child's surface; only the lead one adds
      # the host's runtime extensions, and those carry the operator's home, so
      # the module rather than this output supplies them.
      package =
        variant:
        repoPkgs.pi-bolt.override {
          inherit variant;
          plugins = compiledPlugins registry variant;
        };
    in
    {
      packages.pi-bolt = package "lead";
      packages.pi-bolt-child = package "child";
    };

  flake.modules.homeManager.pi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      stockPi = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;
      # The Claude subscription path: pi-claude-bridge drives this executable
      # through the Agent SDK, and reads the path below rather than resolving
      # `claude` on PATH.
      claudeCode = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

      json = pkgs.formats.json { };

      # Pi agent dir; referenced by rendered settings and out-of-store symlinks.
      piAgentDir = "${config.home.homeDirectory}/.pi/agent";
      # Rows are the single list of extensions: the settings list and the
      # launcher both read them, so nothing can be installed for one and dropped
      # by the other.
      piExtensionRows = import ./_pi-extensions.nix;
      # A row's source or path carries one placeholder: `@home@` for the
      # operator's home, `@extensions@` for the pinned pi-extensions input,
      # `@package@<name>[/subpath]` for an extension package, or `@recipe@<id>`
      # for a source a pkgs/pi-plugins recipe resolves — so the
      # running configuration never reads a live checkout.
      rowPath =
        value:
        if lib.hasPrefix "@recipe@" value then
          pkgs.pi-plugins.plugins.${lib.removePrefix "@recipe@" value}.dir
        else if lib.hasPrefix "@package@" value then
          let
            parts = lib.splitString "/" (lib.removePrefix "@package@" value);
            package = toString pkgs.${builtins.head parts};
            suffix = lib.concatStringsSep "/" (builtins.tail parts);
          in
          if suffix == "" then package else "${package}/${suffix}"
        else
          lib.replaceStrings
            [ "@home@" "@extensions@" ]
            [ config.home.homeDirectory "${inputs.pi-extensions}" ]
            value;
      # A row with no settings source is compiled-only (pi-vcc), so it is neither
      # installed nor passed as -e.
      loadable = row: (row.load or true) && row ? source;
      # Compiled plugins are enabled as builtins by the launcher; only these
      # remaining extensions need a runtime path passed as -e.
      runtimeRows = lib.filter (
        row: loadable row && !(lib.elem "lead" (row.compiled or [ ]))
      ) piExtensionRows;
      pathlessRows = map (row: row.id) (lib.filter (row: (row.path or null) == null) runtimeRows);
      # A compiled row with no recipe fails as a missing attribute; name the row.
      missingRecipes = map (row: row.id) (
        lib.filter (
          row: (row.compiled or [ ]) != [ ] && !(pkgs.pi-plugins.plugins ? ${row.id})
        ) piExtensionRows
      );
      piBoltExtensions = map (row: rowPath row.path) (
        lib.filter (row: (row.path or null) != null) runtimeRows
      );

      # The base every child gets, written for upstream pi: denying extension
      # discovery also denies Pi's built-ins, so MCP and codemode are named back.
      # Per-role additions (provider, web tools) live in the definition that
      # needs them.
      childExtensions = [
        "builtin:mcp"
        "builtin:codemode"
        "${pkgs.pi-otel}"
        "${inputs.pi-extensions}/pi-cbmem/extensions/cbmem.ts"
        "${inputs.pi-extensions}/pi-output-policy/extensions/output-policy.ts"
        "${inputs.pi-extensions}/pi-bash-processes/extensions/background-tasks.ts"
        "${pkgs.pi-magic-context}/dist/index.js"
        "${inputs.pi-extensions}/pi-native-router/src/index.ts"
        "${piAgentDir}/npm/node_modules/pi-tool-repair/tool-repair.ts"
        "${piAgentDir}/npm/node_modules/@gotgenes/pi-permission-system/src/index.ts"
      ];
      childExtensionsYaml = lib.concatStringsSep "\n" (map (path: "  - ${path}") childExtensions);

      # Credentials reach pi by path, not by environment, and only where a
      # credentials aspect is selected — the laptop's phase-1 evaluation selects
      # no sops, and its extensions report a missing credential as before.
      sopsSecrets = (config.sops or { }).secrets or { };

      webSearchKeyConfig = lib.mapAttrs (_field: secret: "!cat ${sopsSecrets.${secret}.path}") (
        lib.filterAttrs (_field: secret: sopsSecrets ? ${secret}) {
          braveApiKey = "BRAVE_API_KEY";
          tavilyApiKey = "TAVILY_API_KEY";
          jinaApiKey = "JINA_TOKEN";
          parallelApiKey = "PARALLEL_API_KEY";
          tinyfishApiKey = "TINYFISH_API_KEY";
          serpdiveApiKey = "SERPDIVE_API_KEY";
          firecrawlApiKey = "FIRECRAWL_API_KEY";
          geminiApiKey = "GEMINI_API_KEY";
          datalabApiKey = "DATALAB_API_KEY";
        }
      );

      # Each definition's frontmatter picks one of these; the list is a ceiling,
      # not a preference order.
      workhorseModels = [
        "route/coder"
        "route/budget"
        "openai-codex/gpt-6-luna"
        "omniroute/coder-high"
        "omniroute/budget"
        "omniroute/smart-budget"
      ];

      # The keys this repository owns in herdsman's app-written config: the two
      # bundled roles whose vocabulary duplicates worker and delegate, and the
      # per-role model allow-lists. A scope only restricts.
      herdsmanConfig = builtins.toJSON {
        retainWorkers = false;
        softTimeoutMs = 1800000;
        workerCompaction = false;
        disabledDefinitions = [
          "generalist"
          "implementer"
        ];
        modelScopes = {
          allow = workhorseModels ++ [
            "omniroute/explorer"
            "openai-codex/gpt-6.1-sol"
          ];
          agents = {
            worker.allow = workhorseModels;
            delegate.allow = workhorseModels;
            researcher.allow = workhorseModels;
            "evidence-auditor".allow = workhorseModels;
            scout.allow = [
              "omniroute/explorer"
              "route/explorer"
            ];
            oracle.allow = [
              "openai-codex/gpt-6.1-sol"
              "route/smart"
            ];
            reviewer.allow = [
              "openai-codex/gpt-6.1-sol"
              "route/smart"
            ];
          };
        };
      };

      # Pi materialises a missing or stale source here on next start. A row with
      # `load = false` is still installed; `overrides` is what keeps it out of a
      # discovery-based session.
      packages = map (
        row:
        if row.overrides or { } == { } then
          rowPath row.source
        else
          { source = rowPath row.source; } // row.overrides
      ) (lib.filter (row: row ? source) piExtensionRows);

      # The package owns both entrypoints and the payload they sit beside; this
      # module owns what varies with the operator — which plugins each build
      # compiles, and the runtime extensions the lead passes by path.
      piBolt = pkgs.pi-bolt.override {
        variant = "lead";
        plugins = compiledPlugins pkgs.pi-plugins "lead";
        extensions = piBoltExtensions;
      };
      piBoltChild = pkgs.pi-bolt.override {
        variant = "child";
        plugins = compiledPlugins pkgs.pi-plugins "child";
      };
      # The lead package ships `bin/pi` beside `bin/pi-bolt`; hiPrio outranks the
      # stock package's own `pi`, which stays reachable as `pi-stock`.
      alias =
        name: target:
        pkgs.runCommand name { } ''
          mkdir -p $out/bin
          ln -s ${target} $out/bin/${name}
        '';
      piStock = alias "pi-stock" "${stockPi}/bin/pi";

    in
    {
      imports = [ ./_pi-mcp.nix ];

      # A row that loads with no installed path would be silently absent from a
      # session; a row that compiles with no recipe fails at an attribute.
      assertions = [
        {
          assertion = pathlessRows == [ ];
          message = "pi: these extensions load at runtime but have no installed path, so a Pi-Bolt launch would drop them: ${lib.concatStringsSep ", " pathlessRows}";
        }
        {
          assertion = missingRecipes == [ ];
          message = "pi: these rows compile into a Pi-Bolt build but have no recipe in pkgs/pi-plugins: ${lib.concatStringsSep ", " missingRecipes}";
        }
      ];

      programs.pi-coding-agent = {
        # Unmodified upstream: a local override changes the derivation and loses
        # the binary-cache hit.
        package = stockPi;

        settings = {
          theme = "noctalia";
          npmCommand = [ "bun" ];
          inherit packages;

          defaultProvider = "omniroute";
          defaultModel = "coder-high";

          enabledModels = [
            "anthropic/claude-haiku-5-5"
            "route/coder"
            "route/budget"
            "route/smart"
            "anthropic/claude-opus-5-5"
            "anthropic/claude-sonnet-5-5"
            "openai-codex/gpt-6-luna"
            "openai-codex/gpt-6.1-sol"
            "omniroute/coder-high"
            "omniroute/explorer"
            "omniroute/budget"
            "omniroute/smart-budget"
            "omniroute/vision"
          ];

          compaction.enabled = false;
          transport = "auto";

          # MCP tools go through codemode; ordinary tools stay direct.
          defaultTools = [ "+codemode" ];
          codemode.mode = "on";
          showCacheMissNotices = true;
          collapseChangelog = false;
          quietStartup = false;
          enableInstallTelemetry = false;
          doubleEscapeAction = "tree";
          followUpMode = "all";
          steeringMode = "all";
          hideThinkingBlock = false;

          kendex.extensionManager.config."@vanillagreen/pi-background-tasks" = {
            autoBackgroundBash = true;
            autoBackgroundPatterns = "";
            wakeMessageStyle = "line";
            forcedBackgroundNotifyOnOutput = false;
            defaultTimeoutSeconds = 0;
            defaultSoftTimeoutMs = 1800000;
            exitWakeBatchMs = 1000;
            outputSettleMs = 400;
            outputAlertMaxChars = 2048;
            toolRenderMode = "stacked";
            toolExpandedLogLines = 12;
            showWidget = true;
            backgroundBashShortcut = "alt+.";
            widgetToggleShortcut = "alt+g";
            dashboardShortcut = "f5";
          };

          kendex.extensionManager.config."@vanillagreen/pi-tool-renderer" = {
            glyphStyle = "unicode";
            treeStyle = "unicode";
            thinkingPanel = true;
            toolChrome = "outlines";

            readOutputMode = "preview";
            readPreviewLines = 40;
            searchOutputMode = "preview";
            searchPreviewLines = 40;
            bashOutputMode = "opencode";
            bashPreviewLines = 40;
            renderMutationTools = true;
            assistantMessageStyle = "agent";
            assistantTurnRule = true;

            messageStamps = "inline";
            messageStampFormat = "24h";
            messageStampSeconds = true;

            renderBashDiffs = false;
            renderVcsDiffCommandDiffs = true;
            splitDiffs = true;
            wordDiffHighlights = true;
            shikiDiffs = true;
            styledCodeBlocks = true;

            registerBatchTool = false;
            batchMaxCalls = 8;
            compactUserMessages = true;
            compactSkillMessages = true;
            compactCompactionMessages = true;
            maxLineWidth = 400;
          };

          # Native router: virtual route/<role> models over ordered physical candidates.
          # Shared settings sit on each provider; accounts are only for providers with several
          # keys (OpenCode Go). Keys are sops-decrypted files; a missing key fails closed.
          kendex.extensionManager.config."@vanillagreen/pi-native-router" = {
            providers = {
              opencode-go = {
                name = "OpenCode Go";
                accounts = {
                  go-a = {
                    apiKeyFile = sopsSecrets.OPENCODE_API_KEY.path;
                    quota = {
                      source = "codexbar";
                      provider = "opencodego";
                      account = "main";
                      enforce = true;
                    };
                  };
                  go-b = {
                    apiKeyFile = sopsSecrets.OPENCODE_API_KEY_HOMELAB.path;
                    quota = {
                      source = "codexbar";
                      provider = "opencodego";
                      account = "homelab";
                      enforce = true;
                    };
                  };
                  go-c = {
                    apiKeyFile = sopsSecrets.OPENCODE_API_KEY_UNI.path;
                    quota = {
                      source = "codexbar";
                      provider = "opencodego";
                      account = "uni";
                      enforce = true;
                    };
                  };
                };
              };
              commandcode = {
                name = "Command Code";
                apiKeyFile = sopsSecrets.COMMANDCODE_API_KEY.path;
                quota = {
                  source = "codexbar";
                  provider = "commandcode";
                  enforce = true;
                };
              };
              "openai-codex" = {
                name = "Codex";
                quota = {
                  source = "codexbar";
                  provider = "codex";
                  enforce = true;
                };
              };
              anthropic = {
                name = "Claude";
                quota = {
                  source = "codexbar";
                  provider = "claude";
                  enforce = true;
                };
              };
            };
            routes = {
              coder.candidates = [
                {
                  provider = "anthropic";
                  id = "claude-haiku-5-5";
                  cacheTtlMs = 3600000;
                  thinkingLevel = "high";
                }
                {
                  provider = "commandcode";
                  id = "deepseek/deepseek-v4.1-flash";
                  cacheTtlMs = 10800000;
                  thinkingLevel = "medium";
                }
                {
                  provider = "opencode-go";
                  id = "deepseek-v4.1-flash";
                  cacheTtlMs = 10800000;
                  thinkingLevel = "medium";
                }
                {
                  provider = "openai-codex";
                  id = "gpt-6-luna";
                  cacheTtlMs = 600000;
                  thinkingLevel = "high";
                }

              ];
              smart.candidates = [
                {
                  provider = "anthropic";
                  id = "claude-opus-5-5";
                  cacheTtlMs = 3600000;
                  thinkingLevel = "medium";
                }
                {
                  provider = "openai-codex";
                  id = "gpt-6.1-sol";
                  cacheTtlMs = 600000;
                  thinkingLevel = "medium";
                }
              ];
              # A bare opencode-go candidate expands to every Go account, in declaration order.
              explorer.candidates = [
                {
                  provider = "opencode-go";
                  id = "deepseek-v4.1-flash";
                  cacheTtlMs = 10800000;
                  thinkingLevel = "medium";
                }
                {
                  provider = "commandcode";
                  id = "deepseek/deepseek-v4.1-flash";
                  cacheTtlMs = 10800000;
                  thinkingLevel = "medium";
                }
              ];
              cheap.candidates = [
                {
                  provider = "anthropic";
                  id = "claude-haiku-5-5";
                  cacheTtlMs = 3600000;
                  thinkingLevel = "high";
                }
                {
                  provider = "opencode-go";
                  id = "mimo-v2.6-flash";
                  cacheTtlMs = 600000;
                  thinkingLevel = "medium";
                }
                {
                  provider = "opencode-go";
                  id = "deepseek-v4.1-flash";
                  cacheTtlMs = 10800000;
                  thinkingLevel = "medium";
                }
              ];
            };
          };

          # pi-jev: advisory mode steers instead of gating; only material harm refuses.
          kendex.extensionManager.config."@vanillagreen/pi-jev" = {
            mode = "advisory";
            # Collect readings without suppressing producer reminders.
            watcherMode = "shadow";
            deliverNudges = false;
            deliverIntentNudges = false;
            deliverSubagentNudges = false;
            orchestratorCheckInMs = 0;
            # Spike guards, not budgets: a past-window request is skipped, not spent.
            rateLimitPerMinute = 60;
            rateLimitPerHour = 1000;
            maxRequestsPerSession = 5000;
          };

          rewind.retention = {
            maxSnapshots = 2000;
            maxAgeDays = 30;
            pinLabeledEntries = true;
          };

          # The compiled footer owns the editor, and `vim` selects its vendored
          # Vim backend; every other setting keeps the extension's default.
          powerline.editor.mode = "vim";
          powerline.editor.frame = "rounded";
          powerline.welcome = false;
          powerline.customItems = [
            {
              id = "provider";
              statusKey = "native-router-provider";
              position = "left";
            }
            {
              id = "model";
              statusKey = "native-router-model";
              position = "left";
            }
            {
              id = "peak";
              statusKey = "native-router-peak";
              position = "left";
              color = "warning";
            }
            {
              id = "thinking";
              statusKey = "native-router-thinking";
              position = "left";
              icon = "󰧑";
              thinkingTint = true;
              color = "accent";
            }
          ];
          # Explicit layout, with no preset dependence. Rounded frame: `left` and
          # `right` share the top border (project/session), `secondary` fills the
          # bottom border (model) before `vim_mode`, `footer` is the stats line
          # under the frame, ahead of the extension statuses.
          # Thinking comes only from the router's custom:thinking item, which shows the
          # level that will run for every model; Pi's built-in thinking segment is omitted.
          powerline.layout = {
            left = [
              "path"
              "git"
              "nix"
            ];
            right = [ "session" ];
            secondary = [
              "model"
              "custom:provider"
              "custom:model"
              "custom:peak"
              "custom:thinking"
              "shell_mode"
              "queue"
              "subagents"
              "vim_mode"
            ];
            footer = [
              [
                "tokens"
                "status:pi-cache-stats"
                "status:reqcap"
              ]
              [
                "cost"
                "context_pct"
              ]
              [ "messages" ]
              [ "tool" ]
              [ "speed" ]
            ];
            footerRight = [ "time" ];
          };
          # Statuses other extensions publish, compacted on the footer line.
          powerline.statusOrder = [ "pi-permission-system" ];
          powerline.statusStyle = "pills";
          powerline.statusFormats = {
            # Context size comes from Powerline's own segment, which has the window.
            magic-context.hide = true;
            rewind.hide = true;
            pi-cache-stats = {
              color = "success";
              replace = [
                [
                  "^.*?cache (\\d+)/(\\d+).*?\\s(\\d+\\.\\d)%(?:·write \\S+)?(.*)$"
                  "󰃨 $1/$2 $3%$4"
                ]
                # Hides the ⚠️ compat marker only: the model's missing compat keys are still there.
                [
                  " ⚠️ compat$"
                  ""
                ]
              ];
            };
            # "reqcap: 1 busts · 125.9k tok" -> "1 bust · 125.9k"; the idle "watching" state is dropped.
            reqcap = {
              icon = "";
              replace = [
                [
                  "^reqcap: watching$"
                  ""
                ]
                [
                  "^reqcap: (\\d+) busts? · (\\S+) tok$"
                  "$1 · $2"
                ]
              ];
            };
            pi-permission-system.replace = [
              [
                "^yolo$"
                ""
              ]
            ];
          };
          powerline.model.showThinkingLevel = false;
          powerline.path.mode = "basename";
          powerline.time = {
            format = "24h";
            showSeconds = true;
          };
        };
      };

      home.packages = [
        claudeCode
        (lib.hiPrio piBolt)
        piBoltChild
        piStock
      ];

      # Session mode is chosen at launch: plain `pi` implements with the user
      # in the loop; `pio` appends the orchestrator stance.
      home.shellAliases.pio = "pi --append-system-prompt ${piAgentDir}/modes/orchestrator.md";

      home.sessionVariables = {
        HINDSIGHT_BASE_URL = hindsightUrl;
        # Powerline guesses Nerd Font support from TERM_PROGRAM, which herdr
        # overrides, so the terminal's Nerd Font is declared here.
        POWERLINE_NERD_FONTS = "1";
      };

      # Files whose writer renames over the path (pi-tool.json, pi-stamp.json)
      # stay application-owned: a rename replaces a store symlink instead of
      # failing. claude-bridge.json writes in place, so it is safe to declare —
      # its startup-notice key is set precisely so the notice never fires and
      # `/login` stays imperative, landing the credential in ~/.claude.
      home.file = {
        # Pi's MCP servers. Underscore ids keep Pi's normalized namespaces
        # stable: the tool names a model sees are mcp__<server>__<tool>.
        ".pi/agent/mcp.json".source = json.generate "pi-native-mcp.json" {
          mcpServers = {
            docs_mcp_server = {
              url = docsMcpUrl;
              description = "Library documentation search, served by the fleet's index on the forge.";
            };
            # GitHub code search is reached mid-investigation, where a codemode
            # script costs more than declaring the one tool.
            grep_app = {
              url = "https://mcp.grep.app";
              exposure = "direct";
            };
            sourcegraph = {
              url = "https://sourcegraph.com/.api/mcp";
              description = "Sourcegraph public-code search: commit, diff, keyword and file lookups.";
            }
            # `!command` is Pi's value form; the token never leaves the secret file.
            // lib.optionalAttrs (sopsSecrets ? SOURCEGRAPH_TOKEN) {
              headers.Authorization = "!printf 'token %s' \"$(cat ${sopsSecrets.SOURCEGRAPH_TOKEN.path})\"";
            };
          }
          # The servers this repository runs register themselves, from the
          # aspect that owns each one (_pi-mcp.nix); what is left above is the
          # endpoints Pi owns.
          // lib.mapAttrs (
            _: lib.filterAttrs (_: value: value != null && value != [ ] && value != { })
          ) config.programs.pi-coding-agent.mcpServers;
        };

        ".pi/agent/pi-fff.json".source = json.generate "pi-fff.json" {
          "$schema" =
            "https://raw.githubusercontent.com/dmtrKovalenko/fff/main/packages/pi-fff/pi-fff.schema.json";
          mode = "override";
        };

        # pi-web-access routing. Each provider key below reads its decrypted
        # sops secret, which takes precedence over the environment fallback.
        # Parallel first while its 60-day credit lasts, then free tiers;
        # useCurrentModel uses the Codex subscription for hosted search when on
        # GPT models, which costs nothing extra.
        ".pi/agent/web-search.json".source = json.generate "pi-web-search.json" (
          {
            searchRouting = {
              providers = [
                "parallel"
                "brave"
                "tavily"
                "jina"
                "serpdive"
                "tinyfish"
                "gemini"
              ];
              useCurrentModel = true;
              fallbackOn = [
                "unsupported"
                "transient"
                "quota"
                "network"
                "invalid-response"
              ];
            };
            # Keys resolve from the decrypted sops secret paths, so no search
            # credential is exported to the environment. pi-web-access prefers a
            # configured value over its environment fallback.
            fetchRouting.providers = [
              "http"
              "firecrawl"
              "jina"
              "parallel"
              "tinyfish"
              "gemini"
            ];
            # Declare the web tools from the first request on every model: a
            # session-wide list shape beats web_enable's per-model variance.
            toolActivation = "eager";
            workflow = "none";
            summaryModel = "omniroute/budget";
          }
          // webSearchKeyConfig
        );

        ".pi/agent/claude-bridge.json".source = json.generate "claude-bridge.json" {
          startupNoticeShown = "2026-09-28";
          provider.pathToClaudeCodeExecutable = "${claudeCode}/bin/claude";
        };

        ".pi/agent/extensions/pi-tool-repair.json".source = json.generate "pi-tool-repair.json" {

          grammarRepair = {
            enabled = true;
            mode = "recover";
            requireKnownTool = true;
            grammars = [
              "dsml"
              "invoke"
              "glm"
            ];
          };

        };
        #
        # Pi-Bolt skips the extension Herdr installs for Pi by name and header
        # marker, so the pane would go unreported. The shim is a link to that
        # same file under a name Pi-Bolt does not recognise: Herdr's own
        # reporter runs again, keeps reporting as `pi`, and follows the file
        # Herdr rewrites on an upgrade. It sits outside the extensions
        # directory so stock Pi's discovery does not load it twice.
        ".pi/agent/herdr-pi-state.ts".source =
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.pi/agent/extensions/herdr-agent-state.ts";

        # Herdsman passes `skills` and `extensions` values to Pi unchanged, so
        # the definitions carry @home@ placeholders instead of a hardcoded home
        # directory and @childExtensions@ for the shared thin base above.
        ".pi/agent/agents".source = pkgs.runCommand "pi-agents" { } ''
          mkdir $out
          for f in ${./pi/agents}/*.md; do
            substitute "$f" "$out/$(basename "$f")" \
              --subst-var-by home ${config.home.homeDirectory} \
              --subst-var-by childExtensions ${lib.escapeShellArg childExtensionsYaml}
          done
        '';

        ".pi/agent/modes".source = ./pi/modes;

        # Global main-agent instructions: skill routing + delegation policy.
        ".pi/agent/AGENTS.md".source = ./pi/AGENTS.md;

        ".pi/agent/skills".source = ./pi/skills;

      };

      # Herdsman's configuration is one app-written file: changing settings
      # through `/agents` rewrites it atomically (temp file plus rename), which
      # is the same write path as herdr's config.toml and would replace a store
      # symlink with a real file. The keys this repository owns are merged
      # recursively into the real file instead, so anything set through the UI
      # survives a switch.
      home.activation.piHerdsmanConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg="$HOME/.pi/agent/pi-herdsman/config.json"
        ${pkgs.coreutils}/bin/mkdir -p "$(dirname "$cfg")"
        if ${pkgs.coreutils}/bin/test -s "$cfg"; then
          ${pkgs.jq}/bin/jq --argjson owned '${herdsmanConfig}' \
            '. * $owned' "$cfg" > "$cfg.new"
        else
          ${pkgs.jq}/bin/jq -n --argjson owned '${herdsmanConfig}' \
            '$owned' > "$cfg.new"
        fi
        ${pkgs.coreutils}/bin/mv -f "$cfg.new" "$cfg"
      '';
    };
}
