{
  config,
  inputs,
  lib,
  ...
}:
let
  # Resolved from the fleet inventory, never a literal in the extension's config.
  hindsightUrl = inputs.nix-fleet.lib.serviceEndpoints.url config.fleet {
    service = "hindsight";
    endpoint = "api";
    via = "tailnet";
  };
  docsMcpUrl = inputs.nix-fleet.lib.serviceEndpoints.url config.fleet {
    service = "docs-mcp";
    endpoint = "mcp";
    via = "tailnet";
  };
  # The payload compiles the recipes of every row that names the lead; the
  # launchers choose what they enable from the ids of the rows that name each.
  compiledRows =
    variant: lib.filter (row: lib.elem variant (row.compiled or [ ])) (import ./_pi-extensions.nix);
  compiledPlugins =
    registry: variant:
    lib.listToAttrs (
      map (row: lib.nameValuePair row.id registry.plugins.${row.id}) (compiledRows variant)
    );
  compiledIds = variant: map (row: row.id) (compiledRows variant);
in
{
  perSystem =
    {
      pkgs,
      system,
      ...
    }:
    let
      repoPkgs = pkgs.extend (import ../../pkgs { inherit inputs system; });
      registry = repoPkgs.pi-plugins;
    in
    {
      # Runtime extensions come from the home module, not from this output.
      packages.pi-bolt = repoPkgs.pi-bolt.override {
        plugins = compiledPlugins registry "lead";
        childPlugins = compiledIds "child";
      };
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
      # Direct use only: Pi's Anthropic subscription auth does not run through it.
      claudeCode = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

      json = pkgs.formats.json { };

      piAgentDir = "${config.home.homeDirectory}/.pi/agent";
      leadAgentDir = "${config.home.homeDirectory}/.pi/roles/lead";
      orchestratorAgentDir = "${config.home.homeDirectory}/.pi/roles/orchestrator";
      childAgentDir = "${config.home.homeDirectory}/.pi/roles/child";
      herdsmanDataDir = "${piAgentDir}/pi-herdsman";
      # Extension rows drive package sources and each role's compiled selection.
      piExtensionRows = import ./_pi-extensions.nix;
      # A row's source or path carries placeholders resolved at build time, never
      # a live checkout.
      rowPath =
        value:
        if lib.hasPrefix "@recipe@" value then
          toString pkgs.pi-plugins.plugins.${lib.removePrefix "@recipe@" value}
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
      # A row with no source is compiled-only (pi-vcc).
      loadable = row: (row.load or true) && row ? source;
      runtimeRows = lib.filter (row: loadable row && (row.compiled or [ ]) == [ ]) piExtensionRows;
      packageSource =
        row:
        if row.overrides or { } == { } then
          rowPath row.source
        else
          { source = rowPath row.source; } // row.overrides;
      runtimePackages = map packageSource runtimeRows;
      childRuntimeIds = [
        "magic-context"
        "native-router"
        "web-access"
      ];
      childPackages = map packageSource (lib.filter (row: lib.elem row.id childRuntimeIds) runtimeRows);
      missingRecipes = map (row: row.id) (
        lib.filter (
          row: (row.compiled or [ ]) != [ ] && !(pkgs.pi-plugins.plugins ? ${row.id})
        ) piExtensionRows
      );

      extensionRow = id: lib.findFirst (row: row.id == id) null piExtensionRows;
      extensionPath = id: rowPath (extensionRow id).path;
      webAccessPath = extensionPath "web-access";
      childExtensionIds = [
        "otel"
        "cbmem"
        "output-policy"
        "bash-processes"
        "magic-context"
        "native-router"
        "tool-repair"
        "permission-system"
      ];
      childExtension =
        id:
        let
          row = extensionRow id;
        in
        if lib.elem "child" (row.compiled or [ ]) then "builtin:${id}" else extensionPath id;
      childExtensions = map childExtension childExtensionIds;
      childExtensionsYaml = lib.concatStringsSep "\n" (map (path: "  - ${path}") childExtensions);

      # Secret paths, present only where the sops aspect is selected.
      sopsSecrets = (config.sops or { }).secrets or { };
      codexbarQuota = provider: {
        source = "codexbar";
        inherit provider;
        enforce = true;
      };
      goAccount =
        secret: account:
        lib.optionalAttrs (sopsSecrets ? ${secret}) {
          apiKeyFile = sopsSecrets.${secret}.path;
          quota = codexbarQuota "opencodego" // {
            inherit account;
          };
        };
      haikuCandidate = {
        provider = "anthropic";
        id = "claude-haiku-5-5";
        cacheTtlMs = 3600000;
        thinkingLevel = "high";
      };
      opencodeDeepseekCandidate = {
        provider = "opencode-go";
        id = "deepseek-v4.1-flash";
        cacheTtlMs = 10800000;
        thinkingLevel = "medium";
      };
      commandcodeDeepseekCandidate = {
        provider = "commandcode";
        id = "deepseek/deepseek-v4.1-flash";
        cacheTtlMs = 10800000;
        thinkingLevel = "medium";
      };

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

      mcpServers = {
        docs_mcp_server = {
          url = docsMcpUrl;
          description = "Library documentation search, served by the fleet's index on the forge.";
        };
        grep_app = {
          url = "https://mcp.grep.app";
          exposure = "direct";
        };
        sourcegraph = {
          url = "https://sourcegraph.com/.api/mcp";
          description = "GitHub code search: commit, diff, keyword and file lookups.";
        }
        // lib.optionalAttrs (sopsSecrets ? SOURCEGRAPH_TOKEN) {
          headers.Authorization = "!printf 'token %s' \"$(cat ${sopsSecrets.SOURCEGRAPH_TOKEN.path})\"";
        };
      }
      // lib.mapAttrs (
        _: lib.filterAttrs (_: value: value != null && value != [ ] && value != { })
      ) config.programs.pi-coding-agent.mcpServers;
      mcpConfig = builtins.toJSON { inherit mcpServers; };

      # Each definition's frontmatter picks one of these; the list is a ceiling,
      # not a preference order.
      workhorseModels = [
        "route/coder"
        "route/cheap"
        "openai-codex/gpt-6-luna"
        "omniroute/coder-high"
        "omniroute/budget"
        "omniroute/smart-budget"
      ];

      smartModels = [
        "openai-codex/gpt-6.1-sol"
        "route/smart"
      ];
      # Rendered whole and read-only to the extension. Model lists only restrict;
      # omitted keys take the extension's defaults.
      herdsmanConfig = {
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
            oracle.allow = smartModels;
            reviewer.allow = smartModels;
          };
        };
      };

      packages = map packageSource (lib.filter (row: row ? source) piExtensionRows);
      # A role's selection: the plugins its payload compiled, plus the packages it
      # loads at run time. Closed because a role directory is Pi-Bolt's alone.
      selectFor =
        role:
        piBolt.payload.select {
          plugins =
            lib.filter (plugin: lib.elem plugin.piBolt.name (compiledIds role)) piBolt.payload.passthru.plugins
            ++ (if role == "child" then childPackages else runtimePackages);
          closed = true;
          enable = [
            "mcp"
            "codemode"
          ]
          ++ lib.optionals (role != "child") [
            "tool-search"
            "llama.cpp"
          ];
        };
      roleSettings =
        let
          settingsFor =
            role: lib.recursiveUpdate config.programs.pi-coding-agent.settings (selectFor role).settings;
          lead = settingsFor "lead";
        in
        {
          lead = lead // {
            extensions = lead.extensions ++ [ "${leadAgentDir}/herdr-pi-state.ts" ];
          };
          orchestrator = settingsFor "orchestrator";
          child = (settingsFor "child") // {
            sessionDir = "${childAgentDir}/sessions";
          };
        };
      roleDirs = {
        lead = leadAgentDir;
        orchestrator = orchestratorAgentDir;
        child = childAgentDir;
      };
      sharedRuntimeEntries = [
        "auth.json"
        "trust.json"
        "mcp-auth.json"
        "loop-police.json"
        "loop-police.jsonl"
        "npm"
        "git"
        "cache"
        "bin"
        "themes"
        "kendex"
        "fff"
        "extension-data"
        "pi-jev"
        "pi-native-router"
        "powerline-footer"
        "extensions/pi-permission-system"
      ]
      ++ map (name: "pi-freeflow${name}") [
        "-cline-pool.json"
        "-onboarded"
        "-opencode-version.json"
        "-update.json"
        "-upstream-health.json"
      ];
      roleSettingsFiles = lib.mapAttrs (
        name: settings: json.generate "pi-${name}-settings.json" settings
      ) roleSettings;

      piBolt = pkgs.pi-bolt.override {
        plugins = compiledPlugins pkgs.pi-plugins "lead";
        childPlugins = compiledIds "child";
        inherit
          leadAgentDir
          childAgentDir
          orchestratorAgentDir
          herdsmanDataDir
          ;
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

      # Reports every compiled row without a recipe; a missing attribute would name only the first.
      assertions = [
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

          defaultProvider = "route";
          defaultModel = "coder";
          defaultProjectTrust = "always";

          enabledModels = [
            "anthropic/claude-haiku-5-5"
            "route/explorer"
            "route/coder"
            "route/budget"
            "route/smart"
            "route/free"
            "anthropic/claude-opus-5-5"
            "anthropic/claude-sonnet-5-5"
            "openai-codex/gpt-6-luna"
            "openai-codex/gpt-6.1-sol"
          ];

          compaction.enabled = false;
          # No automatic keep-alive refreshes: each refresh is a real billed request (quota on subscription routes).
          cacheWarming = "off";
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
            splitDiffs = false;
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
                  go-a = goAccount "OPENCODE_API_KEY" "main";
                  go-b = goAccount "OPENCODE_API_KEY_HOMELAB" "homelab";
                  go-c = goAccount "OPENCODE_API_KEY_UNI" "uni";
                };
              };
              commandcode = lib.optionalAttrs (sopsSecrets ? COMMANDCODE_API_KEY) {
                name = "Command Code";
                apiKeyFile = sopsSecrets.COMMANDCODE_API_KEY.path;
                quota = codexbarQuota "commandcode";
              };
              "openai-codex" = {
                name = "Codex";
                quota = codexbarQuota "codex";
              };
              anthropic = {
                name = "Claude";
                quota = codexbarQuota "claude";
              };
              freeflow = {
                name = "Free";
              };
            };
            routes = {
              coder.candidates = [
                haikuCandidate
                commandcodeDeepseekCandidate
                opencodeDeepseekCandidate
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
                  id = "claude-sonnet-5-5";
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
                opencodeDeepseekCandidate
                commandcodeDeepseekCandidate
              ];
              cheap.candidates = [
                haikuCandidate
                {
                  provider = "opencode-go";
                  id = "mimo-v2.6-flash";
                  cacheTtlMs = 600000;
                  thinkingLevel = "medium";
                }
                opencodeDeepseekCandidate
              ];
              free.candidates = [
                {
                  provider = "freeflow";
                  id = "z-ai/glm-5.3-flash";
                  thinkingLevel = "high";
                }
                {
                  provider = "freeflow";
                  id = "deepseek-v4.1-flash-free";
                  thinkingLevel = "high";
                }
                {
                  provider = "freeflow";
                  id = "muse-spark-1.3-contributor-free";
                  thinkingLevel = "xhigh";
                }
                {
                  provider = "freeflow";
                  id = "cline-free/muse-spark-1.3-contributor";
                  thinkingLevel = "xhigh";
                }
                {
                  provider = "freeflow";
                  id = "mimo-v2.6-flash-free";
                  thinkingLevel = "high";
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
              id = "route-health";
              statusKey = "native-router-pin-health";
              position = "left";
              color = "warning";
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
              "custom:route-health"
              "custom:peak"
              "custom:thinking"
              "shell_mode"
              "queue"
              "subagents"
              "vim_mode"
            ];
            # Footer fitting keeps leading groups first: context and cache hit rate win narrow widths.
            footer = [
              [ "context_pct" ]
              [ "status:pi-cache-stats" ]
              [ "tokens" ]
              [ "status:reqcap" ]
              [ "status:pi-herdsman" ]
              [ "status:pi-herdsman-waiting" ]
              [ "cost" ]
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
        piStock
      ];

      # Plain `pi` uses the lead role; `pio` uses the orchestrator role and shares
      # the operator session history.
      home.shellAliases.pio = "pi-bolt-orchestrator --append-system-prompt ${orchestratorAgentDir}/modes/orchestrator.md";

      home.sessionVariables = {
        HINDSIGHT_BASE_URL = hindsightUrl;
        PI_HERDSMAN_DATA_DIR = herdsmanDataDir;
      };

      home.file =
        let
          agentFiles = {
            # Pi rewrites these through a rename; force re-links them instead of backing up.
            ".pi/agent/mcp.json" = {
              text = mcpConfig;
              force = true;
            };
            ".config/rpiv-todo/config.json".source = json.generate "rpiv-todo.json" {
              collapseKey = "ctrl+alt+t";
              maxWidgetLines = 5;
            };

            ".pi/agent/pi-herdsman/config.json".source = json.generate "pi-herdsman-config.json" herdsmanConfig;

            ".pi/agent/pi-fff.json".source = json.generate "pi-fff.json" {
              "$schema" =
                "https://raw.githubusercontent.com/dmtrKovalenko/fff/main/packages/pi-fff/pi-fff.schema.json";
              mode = "override";
            };

            # Provider keys read their decrypted sops secrets, ahead of the environment.
            # useCurrentModel routes hosted search through the Codex subscription on GPT models.
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
            # the definitions use substituted paths and @childExtensions@ for their
            # shared compiled/runtime base.
            ".pi/agent/agents".source = pkgs.runCommand "pi-agents" { } ''
              mkdir $out
              for f in ${./pi/agents}/*.md; do
                substitute "$f" "$out/$(basename "$f")" \
                  --subst-var-by home ${config.home.homeDirectory} \
                  --subst-var-by webAccess ${lib.escapeShellArg webAccessPath} \
                  --subst-var-by childExtensions ${lib.escapeShellArg childExtensionsYaml}
              done
            '';

            ".pi/agent/modes".source = ./pi/modes;

            # Global main-agent instructions: skill routing + delegation policy.
            ".pi/agent/AGENTS.md".source = ./pi/AGENTS.md;

            ".pi/agent/skills".source = ./pi/skills;

          };
          relative = name: lib.removePrefix ".pi/agent/" name;
          roleFiles =
            role:
            let
              dir = ".pi/roles/${role}";
            in
            lib.mapAttrs' (name: value: lib.nameValuePair "${dir}/${relative name}" value) agentFiles
            // lib.listToAttrs (
              map (
                entry:
                lib.nameValuePair "${dir}/${entry}" {
                  source = config.lib.file.mkOutOfStoreSymlink "${piAgentDir}/${entry}";
                }
              ) (sharedRuntimeEntries ++ lib.optional (role != "child") "sessions")
            )
            // {
              "${dir}/settings.json" = {
                source = roleSettingsFiles.${role};
                force = true;
              };
            };
        in
        agentFiles
        // lib.concatMapAttrs (role: _: roleFiles role) roleDirs
        // {
          "${config.programs.pi-coding-agent.configDir}/settings.json".force = true;
        };
    };
}
