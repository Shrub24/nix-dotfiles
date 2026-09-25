{ config, inputs, ... }:
let
  omniroute = config.topology.services.omniroute.host;
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
      json = pkgs.formats.json { };

      # Pi agent dir; referenced by rendered settings and out-of-store symlinks.
      piAgentDir = "${config.home.homeDirectory}/.pi/agent";

      # Local extension checkouts live under ~/Projects, not at a mountpoint:
      # the home tree moved to the data disk and the mountpoint is a storage
      # fact (see modules/hosts/legion/_storage.nix), not something consumers
      # name. Paths through here survive a mountpoint rename unchanged.
      piExtensions = name: "${config.home.homeDirectory}/Projects/dev/custom/pi-extensions/${name}";
      piOmniroute = "${config.home.homeDirectory}/Projects/dev/custom/OmniRoute/@omniroute/pi-agent";

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

      # Pi materialises a missing or stale source here on next start.
      packages = [
        "npm:pi-web-access"
        "npm:pi-mcp-adapter"
        "npm:@cortexkit/pi-magic-context"
        {
          source = "git:github.com/tmustier/pi-extensions";
          extensions = [ "session-recap/index.ts" ];
          skills = [ ];
        }
        "npm:pi-rewind-hook"
        # "npm:pi-interactive-shell"
        # "git:github.com/DietrichGebert/ponytail"
        {
          source = "git:github.com/ayghri/i-have-adhd";
          skills = [ ];
        }
        "npm:@narumitw/pi-tool"
        "npm:@narumitw/pi-btw"
        "npm:@narumitw/pi-herdr"
        "npm:pi-context-view"
        "npm:pi-vim"
        "npm:@narumitw/pi-starship"
        "extensions/omniroute"
        "npm:@ff-labs/pi-fff"
        "npm:pi-draft-history"
        "${piExtensions "pi-subagents"}"
        "${piExtensions "pi-cbmem"}"
        "npm:@juicesharp/rpiv-ask-user-question"
        "npm:pi-boomerang"
        "npm:pi-cache-optimizer"
        "${piExtensions "pi-bash-processes"}"
        "${piExtensions "pi-tool-renderer"}"
        "npm:@vanillagreen/pi-extension-manager"
        "${piExtensions "pi-output-policy"}"
        "npm:@gotgenes/pi-permission-system"
        "npm:pi-typesafe"
        "npm:pi-intercom"
        "npm:pi-loop-police"
        # Package dir, not entry files — a file path fails with "package source not found".
        "${piExtensions "pi-jev"}"
        "npm:pi-tool-repair"
        # "npm:@howaboua/pi-codex-conversion"
        # "npm:@vanillagreen/pi-hooks"
        # "@spences10/pi-context"
      ];
    in
    {
      programs.pi-coding-agent = {
        package =
          (inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi.override {
            useBun = true;
          }).overrideAttrs
            (old: {
              preInstall =
                builtins.replaceStrings
                  [ "bun build --compile ./dist/bun/cli.js" ]
                  [
                    "bun build --compile --no-compile-autoload-bunfig --compile-autoload-package-json ./dist/bun/cli.js"
                  ]
                  old.preInstall;
              postInstall =
                builtins.replaceStrings
                  [ ''--set PI_PACKAGE_DIR "$pkgdir"'' ]
                  [ ''--set PI_PACKAGE_DIR "$pkgdir" --set PI_SUBAGENT_PI_BINARY "$out/libexec/pi/pi"'' ]
                  old.postInstall;
            });

        settings = {
          theme = "noctalia";
          npmCommand = [ "bun" ];
          inherit packages;

          defaultProvider = "omniroute";
          defaultModel = "coder-high";

          enabledModels = [
            "openai-codex/gpt-5.6-sol"
            "omniroute/coder-high"
            "omniroute/explorer"
            "omniroute/budget"
            "omniroute/smart-budget"
            "omniroute/vision"
          ];

          compaction.enabled = false;
          transport = "auto";
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

            registerBatchTool = true;
            batchMaxCalls = 8;
            compactUserMessages = true;
            compactSkillMessages = true;
            compactCompactionMessages = true;
            maxLineWidth = 400;
          };

          # pi-jev: advisory mode steers instead of gating; only material harm refuses.
          kendex.extensionManager.config."@vanillagreen/pi-jev" = {
            mode = "advisory";
            deliverNudges = true;
            deliverIntentNudges = true;
            deliverSubagentNudges = false;
            orchestratorCheckInMs = 0;
          };

          # Replacement list, not additive; absolute paths (runner children
          # resolve relative ones against cwd, not the agent dir).
          subagents = {
            disableBuiltins = true;
            defaultExtensions = [
              "${piAgentDir}/extensions/omniroute/src/index.ts"
              # codebase-memory over MCP stdio (pi-cbmem workspace member).
              "${piExtensions "pi-cbmem"}/extensions/cbmem.ts"
              "${piAgentDir}/npm/node_modules/pi-mcp-adapter/index.ts"
              "${piAgentDir}/npm/node_modules/@ff-labs/pi-fff/src/index.ts"
              # Spec-hash install dir; stable across content updates.
              "${piAgentDir}/tmp/extensions/git-github.com/363c5354/DietrichGebert/ponytail/pi-extension/index.js"
              # Tool-result truncation + bash backgrounding for children:
              # children run the heaviest greps/reads and would otherwise
              # pull 80K-token tool results into their own context.
              "${piExtensions "pi-output-policy"}/extensions/output-policy.ts"
              "${piExtensions "pi-bash-processes"}/extensions/background-tasks.ts"
              # Child entry of magic-context (NOT dist/index.js, which is the
              # parent session manager): registers ctx_search + todowrite and
              # deliberately omits session-scoped tools.
              "${piAgentDir}/npm/node_modules/@cortexkit/pi-magic-context/dist/subagent-entry.js"
            ];
            defaultProvider = "omniroute";
          };

          rewind.retention = {
            maxSnapshots = 2000;
            maxAgeDays = 30;
            pinLabeledEntries = true;
          };
        };
      };

      # pi-tool.json, pi-stamp.json, and pi-herdr.json stay application-owned:
      # they save with a temporary file plus rename(), which replaces a store
      # symlink with a real file instead of failing.
      home.file = {
        # Shared CortexKit config (Pi + OpenCode read the same file).
        # Runtime only reads it; the doctor CLI writes it only when absent,
        # so a store symlink is safe here.
        ".config/cortexkit/magic-context.jsonc".source = json.generate "magic-context.json" {
          "$schema" =
            "https://raw.githubusercontent.com/cortexkit/magic-context/master/assets/magic-context.schema.json";
          historian = {
            two_pass = true;
            opencode = {
              model = "opencode-omniroute/budget";
              fallback_models = [
                "opencode/mimo-v2.5-free"
                "opencode/deepseek-v4-flash-free"
                "opencode-go/mimo-v2.5"
              ];
            };
            pi = {
              model = "omniroute/budget";
              fallback_models = [ "omniroute/coder-high" ];
            };
          };
          dreamer.disable = true;
          memory.enabled = true;
          embedding = {
            provider = "openai-compatible";
            model = "embedding";
            endpoint = "${omniroute}/v1";
            api_key = "{env:OMNIROUTE_API_KEY}";
          };
          cache_ttl = {
            default = "30m";
            "codex/*" = "10m";
          };
          toast_duration_ms = 500;
          execute_threshold_tokens.default = 200000;
          smart_drops = true;
        };
        ".pi/agent/mcp.json".source = json.generate "pi-mcp.json" {
          settings = {
            toolPrefix = "server";
            lifecycle = "keep-alive";
            scriptMode = false;
            disableProxyTool = true;
          };
          mcpServers = {
            docs-mcp-server.url = "http://localhost:6280/mcp";
            semble = {
              directTools = true;
              command = "uvx";
              args = [
                "--from"
                "semble[mcp]"
                "semble"
              ];
            };
            nixos = {
              directTools = true;
              command = "uvx";
              args = [ "mcp-nixos" ];
            };
            "grep.app" = {
              url = "https://mcp.grep.app";
              directTools = true;
            };
            sourcegraph = {
              url = "https://sourcegraph.com/.api/mcp";
            }
            # `!command` is the adapter's value form; the token never leaves the
            # decrypted secret file.
            // lib.optionalAttrs (sopsSecrets ? SOURCEGRAPH_TOKEN) {
              headers.Authorization = "!printf 'token %s' \"$(cat ${sopsSecrets.SOURCEGRAPH_TOKEN.path})\"";
            };
          }
          // lib.optionalAttrs (config.programs.memex.enable or false) {
            memex = {
              # "search" keeps the six memex tools inactive, reachable only
              # through the mcp proxy — which also stays visible.
              directTools = "search";
              command = "memex";
              args = [
                "mcp"
                "--transport"
                "stdio"
              ];
            };
          };
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
            workflow = "none";
            summaryModel = "omniroute/budget";
          }
          // webSearchKeyConfig
        );

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

        ".pi/agent/agents".source = ./pi/agents;

        # Global main-agent instructions: skill routing + delegation policy.
        ".pi/agent/AGENTS.md".source = ./pi/AGENTS.md;

        ".pi/agent/skills".source = ./pi/skills;

        # Out-of-store symlink so the fork is edited in place, no rebuild needed.
        ".pi/agent/extensions/omniroute".source = config.lib.file.mkOutOfStoreSymlink piOmniroute;
      };
    };
}
