{ inputs, ... }:
{
  flake.modules.homeManager.pi =
    { config, pkgs, ... }:
    let
      json = pkgs.formats.json { };

      # Pi agent dir; referenced by rendered settings and out-of-store symlinks.
      piAgentDir = "${config.home.homeDirectory}/.pi/agent";

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
        "/mnt/LinuxData/Projects/dev/custom/pi-extensions/pi-subagents"
        "npm:@juicesharp/rpiv-ask-user-question"
        "npm:pi-boomerang"
        "npm:pi-cache-optimizer"
        "/mnt/LinuxData/Projects/dev/custom/pi-extensions/pi-bash-processes"
        "/mnt/LinuxData/Projects/dev/custom/pi-extensions/pi-tool-renderer"
        "npm:@vanillagreen/pi-extension-manager"
        "npm:@vanillagreen/pi-output-policy"
        "npm:@gotgenes/pi-permission-system"
        "npm:pi-typesafe"
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

        # Rendered to ~/.pi/agent/settings.json as a read-only store path.
        # `lastChangelogVersion` is deliberately absent: with it set, Pi
        # re-attempts a write that cannot succeed.
        settings = {
          # Noctalia renders ~/.pi/agent/themes/noctalia.json from the live palette.
          theme = "noctalia";
          npmCommand = [ "bun" ];
          inherit packages;

          defaultModel = "omniroute/coder-high";

          enabledModels = [
            "openai-codex/gpt-5.6-sol"
            "omniroute/coder-high"
            "omniroute/explorer"
            "omniroute/budget"
            "omniroute/smart-budget"
            "omniroute/vision"
            "opencode/muse-spark-1.3-contributor-free"
          ];

          compaction.enabled = false;
          transport = "auto";
          showCacheMissNotices = true;
          collapseChangelog = false;
          quietStartup = false;
          enableInstallTelemetry = false;
          doubleEscapeAction = "tree";
          # Drain every queued follow-up as one prompt. Background-task exit
          # wakes are queued follow-ups: this is what lets Pi coalesce several
          # completions into a single turn instead of one turn each.
          followUpMode = "all";
          tuiMode = "regular";
          hideThinkingBlock = false;

          # Slow-command seed list from 65k historical bash timings (p90 >= 10s,
          # high-confidence forms only). newline-separated; # comments, /re/flags.
          kendex.extensionManager.config."@vanillagreen/pi-background-tasks" = {
            autoBackgroundBash = true;
            # Pattern list intentionally empty: commands stay foreground and only
            # yield on time (foregroundYieldMs). Re-add patterns here when forced
            # backgrounding is wanted again (nix/rebuild/test/build commands).
            autoBackgroundPatterns = "";
            # Wake notifications render as one dim line instead of a ruled banner.
            wakeMessageStyle = "line";
            forcedBackgroundNotifyOnOutput = false;
            defaultTimeoutSeconds = 0;
            outputSettleMs = 400;
            outputAlertMaxChars = 2048;
            toolRenderMode = "stacked";
            toolExpandedLogLines = 12;
            showWidget = true;
            # Force-next-bash-to-background; arm then run the command.
            # alt+g not alt+h: herdr-splits owns alt+hjkl for pane resize.
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

            # Inline message timestamps (replaces the pi-stamp extension): dim
            # clock at the right edge of each message's own last line, plus the
            # assistant response duration when it is known.
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

          # Replacement list, not additive; absolute paths (runner children
          # resolve relative ones against cwd, not the agent dir).
          subagents = {
            disableBuiltins = true;
            defaultExtensions = [
              "${piAgentDir}/extensions/omniroute/src/index.ts"
              # Official codebase-memory adapter (regenerated by
              # `codebase-memory-mcp install --clients=pi`); pi-cbm was
              # dropped as unmaintained.
              "${piAgentDir}/extensions/cbmem.ts"
              "${piAgentDir}/npm/node_modules/pi-mcp-adapter/index.ts"
              "${piAgentDir}/npm/node_modules/@ff-labs/pi-fff/src/index.ts"
              # Spec-hash install dir; stable across content updates.
              "${piAgentDir}/tmp/extensions/git-github.com/363c5354/DietrichGebert/ponytail/pi-extension/index.js"
              # Tool-result truncation + bash backgrounding for children:
              # children run the heaviest greps/reads and would otherwise
              # pull 80K-token tool results into their own context.
              "${piAgentDir}/npm/node_modules/@vanillagreen/pi-output-policy/extensions/output-policy.ts"
              "/mnt/LinuxData/Projects/dev/custom/pi-extensions/pi-bash-processes/extensions/background-tasks.ts"
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
            endpoint = "http://home-forge:20128/v1";
            api_key = "{env:OMNIROUTE_API_KEY}";
          };
          cache_ttl = {
            default = "30m";
            "codex/*" = "15m";
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
              headers.Authorization = "token $env:SOURCEGRAPH_TOKEN";
            };
          };
        };

        ".pi/agent/pi-fff.json".source = json.generate "pi-fff.json" {
          "$schema" =
            "https://raw.githubusercontent.com/dmtrKovalenko/fff/main/packages/pi-fff/pi-fff.schema.json";
          mode = "override";
        };

        # pi-web-access routing. Provider keys auto-detect from the session env
        # (rendered by modules/security/credentials/agents.nix) — no key config
        # here. Parallel first while its 60-day credit lasts, then free tiers;
        # useCurrentModel uses the Codex subscription for hosted search when on
        # GPT models, which costs nothing extra.
        ".pi/agent/web-search.json".source = json.generate "pi-web-search.json" {
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
        };

        ".pi/agent/extensions/subagent/config.json".source = json.generate "pi-subagents-config.json" {
          fleetView = true;
          toolDescriptionMode = "compact";
          inlineToolDisplay = "rich";
          missions.enabled = false;
          scheduledRuns.enabled = false;
        };
        #
        # ".pi/agent/pi-auto-permissions/config.json".source =
        #   json.generate "pi-auto-permissions-config.json"
        #     {
        #       rules = [
        #         {
        #           pattern = "\\bgit\\s+commit\\b";
        #           flags = "i";
        #           level = "guarded";
        #           group = "git";
        #           label = "Git commit";
        #         }
        #         {
        #           pattern = "\\bgit\\s+push\\b";
        #           flags = "i";
        #           level = "guarded";
        #           group = "git";
        #           label = "Git push";
        #         }
        #         {
        #           pattern = "\\bnh\\s+(os|home)\\s+(switch|boot)\\b";
        #           flags = "i";
        #           level = "guarded";
        #           group = "nix";
        #           label = "NixOS/home-manager switch";
        #         }
        #         {
        #           pattern = "\\bnpm\\s+publish\\b";
        #           flags = "i";
        #           level = "guarded";
        #           group = "npm";
        #           label = "npm publish";
        #         }
        #       ];
        #       reviewer = {
        #         provider = "omniroute";
        #         model = "coder-high";
        #         reasoningEffort = "low";
        #         timeoutMs = 30000;
        #       };
        #     };
        #
        ".pi/agent/pi-starship.toml".source = ./pi/pi-starship.toml;

        ".pi/agent/agents".source = ./pi/agents;

        # Global main-agent instructions: skill routing + delegation policy.
        ".pi/agent/AGENTS.md".source = ./pi/AGENTS.md;

        ".pi/agent/skills".source = ./pi/skills;

        # Out-of-store symlink so the fork is edited in place, no rebuild needed.
        ".pi/agent/extensions/omniroute".source =
          config.lib.file.mkOutOfStoreSymlink "/mnt/LinuxData/Projects/dev/custom/OmniRoute/@omniroute/pi-agent";
      };
    };
}
