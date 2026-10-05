{ config, inputs, ... }:
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
in
{
  flake.modules.homeManager.pi =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # The Claude subscription path: claude-code is the executable
      # pi-claude-bridge drives via the Agent SDK. Home Manager owns it like any
      # other agent binary (see modules/agents/herdr.nix), and the bridge reads
      # the path below rather than resolving `claude` on PATH.
      claudeCode = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;

      json = pkgs.formats.json { };

      # Pi agent dir; referenced by rendered settings and out-of-store symlinks.
      piAgentDir = "${config.home.homeDirectory}/.pi/agent";

      # Local extension checkouts live under ~/Projects, not at a mountpoint:
      # the home tree moved to the data disk and the mountpoint is a storage
      # fact (see modules/hosts/legion/_storage.nix), not something consumers
      # name. Paths through here survive a mountpoint rename unchanged.
      piExtensions = name: "${config.home.homeDirectory}/Projects/dev/custom/pi-extensions/${name}";
      piOmniroute = "${config.home.homeDirectory}/Projects/dev/custom/OmniRoute/@omniroute/pi-agent";

      # The thin base every subagent gets. Denying extension discovery also
      # drops Pi's built-ins, including MCP and codemode; magic-context
      # loads its child entry, not the parent session manager. Per-role
      # additions (provider, web tools) live in the definition that needs them.
      childExtensions = [
        "builtin:mcp"
        "builtin:codemode"
        "${piExtensions "pi-cbmem"}/extensions/cbmem.ts"
        "${piExtensions "pi-output-policy"}/extensions/output-policy.ts"
        "${piExtensions "pi-bash-processes"}/extensions/background-tasks.ts"
        "${piAgentDir}/npm/node_modules/@cortexkit/pi-magic-context/dist/subagent-entry.js"
        "${piAgentDir}/npm/node_modules/pi-blackhole/dist/index.js"
        "${piAgentDir}/npm/node_modules/pi-tool-repair/tool-repair.ts"
        "${piAgentDir}/npm/node_modules/@gotgenes/pi-permission-system/src/index.ts"
      ];
      childExtensionsYaml = lib.concatStringsSep "\n" (map (path: "  - ${path}") childExtensions);

      # Credentials reach pi by path, not by environment. The wiring is emitted
      # only where the credentials aspect is selected: the laptop's phase-1
      # evaluation selects no sops at all, and the extensions then report a
      # missing credential exactly as they did before the keys were configured
      # here.
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

      # The models a delegated agent may run on. Each agent's frontmatter picks
      # one of them; the list is the ceiling, not a preference order.
      workhorseModels = [
        "openai-codex/gpt-6-luna"
        "omniroute/coder-high"
        "omniroute/budget"
        "omniroute/smart-budget"
      ];

      # Herdsman's configuration is one app-written file. These are the keys this
      # repository owns: `disabledDefinitions` drops the bundled generalist and
      # implementer, whose vocabulary duplicates worker and delegate, and
      # `modelScopes` restores the per-role model allow-lists the previous
      # delegation surface carried. A scope that exists only restricts — a
      # definition's own list can never widen the global one — so each list names
      # the models that definition may actually run on.
      herdsmanConfig = builtins.toJSON {
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
            scout.allow = [ "omniroute/explorer" ];
            oracle.allow = [ "openai-codex/gpt-6.1-sol" ];
            reviewer.allow = [ "openai-codex/gpt-6.1-sol" ];
          };
        };
      };

      # Pi materialises a missing or stale source here on next start.
      packages = [
        "npm:pi-web-access"
        "npm:@cortexkit/pi-magic-context"
        # pi-recap writes its own config (temp file + rename), so its model
        # and multiplexer template stay a one-time `/recap-config` pass.
        "npm:@zhcsyncer/pi-recap"
        "npm:pi-rewind-hook"
        # "npm:pi-interactive-shell"
        {
          source = "git:github.com/ayghri/i-have-adhd";
          skills = [ ];
        }
        "npm:@narumitw/pi-tool"
        # "npm:@narumitw/pi-btw"
        "npm:pi-context-view"
        "npm:pi-vim"
        "npm:@narumitw/pi-starship"
        "extensions/omniroute"
        "npm:@ff-labs/pi-fff"
        "npm:pi-draft-history"
        # "npm:pi-context"
        "${piExtensions "pi-herdsman"}"
        "${piExtensions "pi-cbmem"}"
        "npm:@juicesharp/rpiv-ask-user-question"
        # "npm:pi-boomerang"
        "npm:pi-cache-optimizer"
        "${piExtensions "pi-bash-processes"}"
        "${piExtensions "pi-tool-renderer"}"
        "npm:@vanillagreen/pi-extension-manager"
        "${piExtensions "pi-output-policy"}"
        "${piExtensions "pi-reqcap"}"
        "npm:@gotgenes/pi-permission-system"
        "npm:pi-intercom"
        "npm:pi-loop-police"
        # Package dir, not entry files — a file path fails with "package source not found".
        "${piExtensions "pi-jev"}"
        "npm:pi-tool-repair"
        # `extensions = []` suppresses the manifest entry: installed, not loaded.
        # pi-subagents stays as the fallback delegation surface.
        {
          source = piExtensions "pi-subagents";
          extensions = [ ];
          skills = [ ];
        }
        {
          source = "npm:pi-blackhole";
          extensions = [ ];
          skills = [ ];
        }
        # "npm:@luxusai/pi-hindsight"
        # "npm:pi-claude-bridge"
        "npm:@gotgenes/pi-anthropic-auth"
        # "npm:@howaboua/pi-codex-conversion"
        # "npm:@vanillagreen/pi-hooks"
        # "@spences10/pi-context"
      ];
    in
    {
      imports = [ ./_pi-mcp.nix ];

      programs.pi-coding-agent = {
        # Unmodified upstream package: a local override changes the derivation
        # and loses the binary-cache hit. The Bun compile flags and the codemode
        # worker shims are upstream (numtide/llm-agents.nix#10192), and `useBun`
        # already defaults to true.
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi;

        settings = {
          theme = "noctalia";
          npmCommand = [ "bun" ];
          inherit packages;

          defaultProvider = "omniroute";
          defaultModel = "coder-high";

          enabledModels = [
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

          # Trial: MCP tools use codemode; ordinary tools stay directly available.
          defaultTools = [ "+codemode" ];
          codemode.mode = "on";
          showCacheMissNotices = true;
          collapseChangelog = false;
          quietStartup = false;
          enableInstallTelemetry = false;
          doubleEscapeAction = "tree";
          followUpMode = "all";
          tuiMode = "regular";
          hideThinkingBlock = false;

          kendex.extensionManager.config."@vanillagreen/pi-background-tasks" = {
            autoBackgroundBash = true;
            autoBackgroundPatterns = "";
            wakeMessageStyle = "line";
            forcedBackgroundNotifyOnOutput = false;
            defaultTimeoutSeconds = 0;
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

          # pi-jev: advisory mode steers instead of gating; only material harm refuses.
          kendex.extensionManager.config."@vanillagreen/pi-jev" = {
            mode = "advisory";
            deliverNudges = false;
            deliverIntentNudges = false;
            deliverSubagentNudges = false;
            orchestratorCheckInMs = 0;
            # Spike guards, not budgets: a past-window request is skipped, not spent.
            rateLimitPerMinute = 60;
            rateLimitPerHour = 1000;
            # Spend guard on pi-typesafe's persisted ledger; ~cents at our state sizes.
            maxRequestsPerDay = 5000;
          };

          # Replacement list, not additive; absolute paths (runner children
          # resolve relative ones against cwd, not the agent dir).
          subagents = {
            disableBuiltins = true;
            agentOverrides = {
              reviewer.disabled = true;
              evidence-auditor.disabled = true;
            };
            defaultExtensions = [
              "${piAgentDir}/extensions/omniroute/src/index.ts"
              # codebase-memory over MCP stdio (pi-cbmem workspace member).
              "${piExtensions "pi-cbmem"}/extensions/cbmem.ts"
              # Children resolve mcp:<server> selectors against Pi's built-in
              # MCP (Pi >= 0.99).
              "${piAgentDir}/npm/node_modules/@ff-labs/pi-fff/src/index.ts"
              # Tool-result truncation + bash backgrounding for children:
              # children run the heaviest greps/reads and would otherwise
              # pull 80K-token tool results into their own context.
              "${piExtensions "pi-output-policy"}/extensions/output-policy.ts"
              "${piExtensions "pi-bash-processes"}/extensions/background-tasks.ts"
              # Child entry of magic-context (NOT dist/index.js, which is the
              # parent session manager): registers ctx_search + todowrite and
              # deliberately omits session-scoped tools.
              "${piAgentDir}/npm/node_modules/@cortexkit/pi-magic-context/dist/subagent-entry.js"
              # Compaction for children only.
              "${piAgentDir}/npm/node_modules/pi-blackhole/dist/index.js"
              "${piAgentDir}/npm/node_modules/pi-tool-repair/tool-repair.ts"
              "${piAgentDir}/npm/node_modules/pi-intercom/index.ts"
              "${piAgentDir}/npm/node_modules/pi-loop-police/extensions/index.ts"
            ];
            defaultProvider = "omniroute";

            # Model pools per role: the outer `allow` is the fleet pool and each
            # agent's own list narrows it, since both must match. `strict` is
            # what makes the bound real — without it an out-of-scope frontmatter
            # or parent-inherited model only warns, leaving a per-run
            # `[model=…]` as the only thing actually bounded.
            #
            # sol sits in the outer pool solely for oracle, whose own list is the
            # only place it appears; no working agent can resolve a sol, astra,
            # terra or claude-opus model. Aliases need no entry: they resolve to
            # the canonical agent before the scope is applied.
            modelScope = {
              enforce = true;
              strict = true;
              allow = workhorseModels ++ [
                "omniroute/explorer"
                "openai-codex/gpt-6.1-sol"
              ];
              agents = {
                worker.allow = workhorseModels;
                delegate.allow = workhorseModels;
                researcher.allow = workhorseModels;
                reviewer.allow = workhorseModels;
                evidence-auditor.allow = workhorseModels;
                scout.allow = [ "omniroute/explorer" ];
                oracle.allow = [
                  "openai-codex/gpt-6.1-sol"
                ];
              };
            };
          };

          rewind.retention = {
            maxSnapshots = 2000;
            maxAgeDays = 30;
            pinLabeledEntries = true;
          };
        };
      };

      home.packages = [ claudeCode ];

      # Session mode is chosen at launch: plain `pi` implements with the user
      # in the loop; `pio` appends the orchestrator stance.
      home.shellAliases.pio = "pi --append-system-prompt ${piAgentDir}/modes/orchestrator.md";

      home.sessionVariables = {
        HINDSIGHT_BASE_URL = hindsightUrl;
        PI_BLACKHOLE_MEMORY = "false";
        # Child context limits are NOT handled here: blackhole's mid-run path needs
        # pi's JS module graph (AgentSession.prototype), which a compiled pi does
        # not ship, so any in-run threshold set below is inert for children. The
        # threshold is kept only because blackhole still compacts at run end.
        PI_BLACKHOLE_COMPACT_AFTER_TOKENS = "200000";
      };

      # pi-tool.json and pi-stamp.json stay application-owned: they save with a
      # temporary file plus rename(), which replaces a store symlink with a real
      # file instead of failing.
      #
      # pi-claude-bridge writes claude-bridge.json in place (writeFileSync, no
      # rename), so a symlink survives — its own startup notice being the only
      # write it ever makes. The notice key is declared here for that reason:
      # the notice cannot fire, so the file is never written, and `/login` stays
      # imperative — the credential it writes lands in ~/.claude.
      home.file = {
        # Pi's MCP servers. Underscore ids keep Pi's normalized namespaces and
        # pi-subagents selectors identical.
        ".pi/agent/mcp.json".source = json.generate "pi-native-mcp.json" {
          mcpServers = {
            docs_mcp_server = {
              url = docsMcpUrl;
              description = "Library documentation search, served by the fleet's index on the forge.";
            };
            # One tool with a large schema, and the one server whose tools are
            # worth declaring: GitHub code search is reached mid-investigation,
            # where a codemode script would cost more than the declaration.
            grep_app = {
              url = "https://mcp.grep.app";
              exposure = "direct";
            };
            sourcegraph = {
              url = "https://sourcegraph.com/.api/mcp";
              description = "Sourcegraph public-code search: commit, diff, keyword and file lookups.";
            }
            # `!command` is Pi's value form; the token never leaves the
            # decrypted secret file.
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

        ".pi/agent/extensions/subagent/config.json".source = json.generate "pi-subagents-config.json" {
          fleetView = true;
          toolDescriptionMode = "compact";
          inlineToolDisplay = "rich";
          missions.enabled = false;
          scheduledRuns.enabled = false;
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
        ".pi/agent/pi-starship.toml".source = ./pi/pi-starship.toml;

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

        # Out-of-store symlink so the fork is edited in place, no rebuild needed.
        ".pi/agent/extensions/omniroute".source = config.lib.file.mkOutOfStoreSymlink piOmniroute;
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
