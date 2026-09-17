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
        "npm:@ogulcancelik/pi-auto-permissions"
        "git:github.com/DietrichGebert/ponytail"
        {
          source = "git:github.com/ayghri/i-have-adhd";
          skills = [ ];
        }
        "npm:@narumitw/pi-tool"
        "npm:@narumitw/pi-stamp"
        "npm:@narumitw/pi-btw"
        "npm:@narumitw/pi-herdr"
        "npm:pi-context-view"
        "npm:pi-vim"
        "npm:@narumitw/pi-starship"
        "extensions/omniroute"
        "npm:@ff-labs/pi-fff"
        "npm:pi-cbm"
        "npm:pi-draft-history"
        "/mnt/LinuxData/Projects/dev/custom/pi-extensions/pi-subagents"
        "npm:@juicesharp/rpiv-ask-user-question"
        "npm:pi-boomerang"
        "npm:pi-cache-optimizer"
        "/mnt/LinuxData/Projects/dev/custom/pi-extensions/pi-bash-processes"
        "/mnt/LinuxData/Projects/dev/custom/pi-extensions/pi-tool-renderer"
        "npm:@vanillagreen/pi-extension-manager"
        "npm:@vanillagreen/pi-output-policy"
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

          # Main orchestrator model; agents pin their own in agents/*.md.
          defaultModel = "openai-codex/gpt-5.6-sol";

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
          tuiMode = "regular";
          hideThinkingBlock = false;

          # Slow-command seed list from 65k historical bash timings (p90 >= 10s,
          # high-confidence forms only). newline-separated; # comments, /re/flags.
          kendex.extensionManager.config."@vanillagreen/pi-background-tasks" = {
            autoBackgroundBash = true;
            autoBackgroundPatterns = ''
              # nix / home-manager lifecycle
              /\bnh\s+(home|os)\s+(switch|build|boot)\b/i
              /\bnixos-rebuild\b/i
              /\bsystem-manager\s+switch\b/i
              /\bnix\s+(build|develop|shell|run)\b/i
              /\bnix\s+flake\s+(check|update|lock)\b/i
              /\bnix-prefetch(-url)?\b/i
              # tests / builds
              /\bbun(\s+run)?\s+test\b/i
              /\bpytest\b/i
              /\bcargo\s+(build|test|check|clippy)\b/i
              /\bgo\s+(build|test)\b/i
              /\b(npm|pnpm|bun)\s+(install|ci|add)\b/i
              /\b(uv\s+(sync|pip|venv)|pip3?\s+install)\b/i
              /\b(pre-commit|lefthook)\s+run\b/i
              /\b(pdflatex|latexmk|xelatex|lualatex)\b/i
              /\bagda\b/i
              /\bmatlab(-nv)?\b/i
              /\bhelmfile\b/i
              /\b(docker|podman)\s+(build|pull)\b/i
              /\b(yamlfmt|yamllint)\b/i
              # network / vcs
              /\bgit\s+(clone|fetch|push|pull|remote\s+prune)\b/i
              /\bgit\s+add\s+(-A|--all|\.)\b/i
              /\brsync\b/i
            '';
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

            renderBashDiffs = true;
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
            maxLineWidth = 243;
          };

          # Replacement list, not additive; absolute paths (runner children
          # resolve relative ones against cwd, not the agent dir).
          subagents = {
            defaultExtensions = [
              "${piAgentDir}/extensions/omniroute/src/index.ts"
              "${piAgentDir}/npm/node_modules/pi-cbm/src/index.ts"
              "${piAgentDir}/npm/node_modules/pi-mcp-adapter/index.ts"
              "${piAgentDir}/npm/node_modules/@ff-labs/pi-fff/src/index.ts"
              # Spec-hash install dir; stable across content updates.
              "${piAgentDir}/tmp/extensions/git-github.com/363c5354/DietrichGebert/ponytail/pi-extension/index.js"
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
        ".pi/agent/mcp.json".source = json.generate "pi-mcp.json" {
          mcpServers = {
            docs-mcp-server.url = "http://localhost:6280/mcp";
            semble = {
              command = "uvx";
              args = [
                "--from"
                "semble[mcp]"
                "semble"
              ];
            };
            nixos = {
              command = "uvx";
              args = [ "mcp-nixos" ];
            };
          };
        };

        ".pi/agent/pi-fff.json".source = json.generate "pi-fff.json" {
          "$schema" =
            "https://raw.githubusercontent.com/dmtrKovalenko/fff/main/packages/pi-fff/pi-fff.schema.json";
          mode = "override";
        };

        ".pi/agent/extensions/subagent/config.json".source = json.generate "pi-subagents-config.json" {
          fleetView = true;
          modelExclusions.defaultTtlMs = 300000;
        };

        ".pi/agent/pi-auto-permissions/config.json".source =
          json.generate "pi-auto-permissions-config.json"
            {
              rules = [
                {
                  pattern = "\\bgit\\s+commit\\b";
                  flags = "i";
                  level = "guarded";
                  group = "git";
                  label = "Git commit";
                }
                {
                  pattern = "\\bgit\\s+push\\b";
                  flags = "i";
                  level = "guarded";
                  group = "git";
                  label = "Git push";
                }
                {
                  pattern = "\\bnh\\s+(os|home)\\s+(switch|boot)\\b";
                  flags = "i";
                  level = "guarded";
                  group = "nix";
                  label = "NixOS/home-manager switch";
                }
                {
                  pattern = "\\bnpm\\s+publish\\b";
                  flags = "i";
                  level = "guarded";
                  group = "npm";
                  label = "npm publish";
                }
              ];
              reviewer = {
                provider = "omniroute";
                model = "coder-high";
                reasoningEffort = "low";
                timeoutMs = 30000;
              };
            };

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
