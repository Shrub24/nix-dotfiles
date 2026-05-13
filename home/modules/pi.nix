{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.pi;

  kreuzberg-cli = pkgs.stdenv.mkDerivation {
    pname = "kreuzberg-cli";
    version = "4.9.7";
    src = pkgs.fetchurl {
      url = "https://github.com/kreuzberg-dev/kreuzberg/releases/download/v4.9.7/kreuzberg-cli-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-WTqB5tTrKGnzlVf7tSeDuMpj4YstitGn+9dvOW5rl5o=";
    };
    sourceRoot = "kreuzberg-cli-x86_64-unknown-linux-gnu";
    installPhase = ''
      mkdir -p $out/bin
      cp kreuzberg $out/bin/
      chmod +x $out/bin/kreuzberg
    '';
  };
in
{
  options.programs.pi = {
    enable = lib.mkEnableOption "pi coding agent";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.pi;
      defaultText = lib.literalExpression "pkgs.pi";
      description = "The pi coding agent package to use.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = lib.types.attrs;
        options = {
          defaultProvider = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Default provider (e.g., 'anthropic', 'openai').";
          };

          defaultModel = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = "Default model ID.";
          };

          defaultThinkingLevel = lib.mkOption {
            type = lib.types.nullOr (
              lib.types.enum [
                "off"
                "minimal"
                "low"
                "medium"
                "high"
                "xhigh"
              ]
            );
            default = null;
            description = "Default thinking level for the model.";
          };

          hideThinkingBlock = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Hide thinking blocks in output.";
          };

          theme = lib.mkOption {
            type = lib.types.str;
            default = "dark";
            description = "Theme name ('dark', 'light', or custom).";
          };

          quietStartup = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Hide startup header.";
          };

          compaction = lib.mkOption {
            type = lib.types.submodule {
              freeformType = lib.types.attrs;
              options = {
                enabled = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Enable auto-compaction.";
                };

                reserveTokens = lib.mkOption {
                  type = lib.types.int;
                  default = 16384;
                  description = "Tokens reserved for LLM response.";
                };

                keepRecentTokens = lib.mkOption {
                  type = lib.types.int;
                  default = 20000;
                  description = "Recent tokens to keep (not summarized).";
                };
              };
            };
            default = { };
            description = "Compaction settings.";
          };

          retry = lib.mkOption {
            type = lib.types.submodule {
              freeformType = lib.types.attrs;
              options = {
                enabled = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                  description = "Enable automatic agent-level retry on transient errors.";
                };

                maxRetries = lib.mkOption {
                  type = lib.types.int;
                  default = 3;
                  description = "Maximum agent-level retry attempts.";
                };

                baseDelayMs = lib.mkOption {
                  type = lib.types.int;
                  default = 2000;
                  description = "Base delay for exponential backoff (ms).";
                };
              };
            };
            default = { };
            description = "Retry settings.";
          };

          enabledModels = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Model patterns for Ctrl+P cycling.";
          };

          packages = lib.mkOption {
            type = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
            default = [ ];
            description = "npm/git packages to load resources from.";
          };

          extensions = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Local extension file paths or directories.";
          };

          skills = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Local skill file paths or directories.";
          };

          prompts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Local prompt template paths or directories.";
          };

          themes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Local theme file paths or directories.";
          };

          "observational-memory" = lib.mkOption {
            type = lib.types.submodule {
              freeformType = lib.types.attrs;
              options = {
                observationThresholdTokens = lib.mkOption {
                  type = lib.types.int;
                  default = 1000;
                };
                compactionThresholdTokens = lib.mkOption {
                  type = lib.types.int;
                  default = 50000;
                };
                reflectionThresholdTokens = lib.mkOption {
                  type = lib.types.int;
                  default = 30000;
                };
                passive = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
              };
            };
            default = { };
          };

          "pi-fork" = lib.mkOption {
            type = lib.types.submodule {
              freeformType = lib.types.attrs;
              options = {
                defaultEffort = lib.mkOption {
                  type = lib.types.str;
                  default = "balanced";
                };
                costFooter = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                };
                effortProfiles = lib.mkOption {
                  type = lib.types.attrs;
                  default = { };
                };
              };
            };
            default = { };
          };

          powerline = lib.mkOption {
            type = lib.types.submodule {
              freeformType = lib.types.attrs;
              options = {
                preset = lib.mkOption {
                  type = lib.types.str;
                  default = "nerd";
                };
                fixedEditor = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                };
                mouseScroll = lib.mkOption {
                  type = lib.types.bool;
                  default = true;
                };
              };
            };
            default = { };
          };

          rewind = lib.mkOption {
            type = lib.types.submodule {
              freeformType = lib.types.attrs;
              options = {
                silentCheckpoints = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
                retention = lib.mkOption {
                  type = lib.types.submodule {
                    freeformType = lib.types.attrs;
                    options = {
                      maxSnapshots = lib.mkOption {
                        type = lib.types.int;
                        default = 2000;
                      };
                      maxAgeDays = lib.mkOption {
                        type = lib.types.int;
                        default = 30;
                      };
                      pinLabeledEntries = lib.mkOption {
                        type = lib.types.bool;
                        default = true;
                      };
                    };
                  };
                  default = { };
                };
              };
            };
            default = { };
          };
        };
      };
      default = { };
      description = "Pi coding agent configuration settings.";
    };

    mcp = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "Shared MCP configuration for pi-mcp-adapter.";
    };

    search = lib.mkOption {
      type = lib.types.attrs;
      default = {
        defaultBackend = "auto";
        backends = {
          tavily = {
            enabled = true;
          };
          brave = {
            enabled = true;
          };
          firecrawl = {
            enabled = true;
          };
        };
      };
      description = "pi-search-multi extension configuration.";
    };

    permissionSystem = lib.mkOption {
      type = lib.types.attrs;
      default = {
        debugLog = false;
        permissionReviewLog = true;
        yoloMode = false;
      };
      description = "pi-permission-system extension configuration.";
    };

    permissions = lib.mkOption {
      type = lib.types.attrs;
      default = {
        defaultPolicy = {
          tools = "ask";
          bash = "ask";
          mcp = "ask";
          skills = "ask";
          special = "ask";
        };
        tools = {
          read = "allow";
          edit = "allow";
          ask_user_question = "allow";
          todo = "allow";
          btw = "allow";
          process = "allow";
          web_search = "allow";
          recall = "allow";
          fork = "allow";
          Agent = "allow";
          get_subagent_result = "allow";
          steer_subagent = "allow";
          mcp = "allow";
          lsp_navigation = "allow";
          ast_grep_search = "allow";
        };
        bash = {
          "*" = "ask";
          "bd *" = "allow";
          "ls *" = "allow";
          "fd *" = "allow";
          "rg *" = "allow";
          "grep *" = "allow";
          "cat *" = "allow";
          "head *" = "allow";
          "tail *" = "allow";
          "find *" = "allow";
          "tree *" = "allow";
          "file *" = "allow";
          "echo *" = "allow";
          "wc *" = "allow";
          "uv *" = "allow";
          "uvx *" = "allow";
          "npm *" = "allow";
          "pnpm *" = "allow";
          "yarn *" = "allow";
          "node *" = "allow";
          "python *" = "allow";
          "python3 *" = "allow";
          "pip *" = "allow";
          "pytest *" = "allow";
          "nix *" = "allow";
          "nixfmt *" = "allow";
          "docker *" = "allow";
          "kubectl *" = "allow";
          "task *" = "allow";
          "ruff *" = "allow";
          "date*" = "allow";
          "git status *" = "allow";
          "git diff *" = "allow";
          "git log *" = "allow";
          "git show *" = "allow";
          "cp *" = "allow";
          "mv *" = "allow";
          "mkdir *" = "allow";
          "rmdir *" = "allow";
          "tar *" = "allow";
          "unzip *" = "allow";
          "curl *" = "allow";
          "wget *" = "allow";
          "sort *" = "allow";
          "uniq *" = "allow";
          "which *" = "allow";
          "xdg-open *" = "allow";
          "code *" = "allow";
        };
        mcp = {
          mcp_status = "allow";
          mcp_list = "allow";
          mcp_search = "allow";
          mcp_describe = "allow";
          mcp_connect = "allow";
          "context7:*" = "allow";
          "context-mode:*" = "allow";
          "gh-grep:*" = "allow";
          "semgrep:*" = "allow";
          "jina-reader:*" = "allow";
          "tavily:*" = "allow";
          "brave:*" = "allow";
          "nixos:*" = "allow";
          "markdownify:*" = "allow";
          "github:get*" = "allow";
          "github:list*" = "allow";
          "github:search*" = "allow";
          "github:pull_request_read" = "allow";
          "github:issue_read" = "allow";
          "github:get_me" = "allow";
          "github:get_label" = "allow";
          "github:list_teams" = "allow";
          "github:get_teams" = "allow";
          "github:get_team_members" = "allow";
          "github:add_issue_comment" = "ask";
          "github:add_comment_to_pending_review" = "ask";
          "github:add_reply_to_pull_request_comment" = "ask";
          "github:assign_copilot_to_issue" = "ask";
          "github:create_branch" = "ask";
          "github:create_or_update_file" = "ask";
          "github:create_pull_request" = "ask";
          "github:create_pull_request_with_copilot" = "ask";
          "github:create_repository" = "ask";
          "github:delete_file" = "ask";
          "github:fork_repository" = "ask";
          "github:github_issue_write" = "ask";
          "github:github_sub_issue_write" = "ask";
          "github:github_pull_request_review_write" = "ask";
          "github:github_update_pull_request" = "ask";
          "github:github_update_pull_request_branch" = "ask";
          "github:github_merge_pull_request" = "ask";
          "github:github_get_copilot_job_status" = "ask";
          "github:github_request_copilot_review" = "ask";
          "github:github_push_files" = "ask";
          "github:list_issue_types" = "ask";
          "desktop-commander:*read*" = "allow";
          "desktop-commander:*list*" = "allow";
          "desktop-commander:*get*" = "allow";
          "desktop-commander:*search*" = "allow";
          "desktop-commander:*write*" = "allow";
          "desktop-commander:*create*" = "allow";
          "desktop-commander:*move*" = "allow";
          "desktop-commander:*edit*" = "allow";
          "desktop-commander:*set*" = "allow";
          "desktop-commander:*process*" = "allow";
          "desktop-commander:*kill*" = "ask";
          "desktop-commander:*terminate*" = "ask";
          "desktop-commander:*force*" = "ask";
          desktop_commander = "ask";
        };
        special = {
          external_directory = "ask";
          doom_loop = "ask";
        };
      };
      description = "pi-permission-system global policy.";
    };

    subagents = lib.mkOption {
      type = lib.types.attrs;
      default = {
        maxConcurrent = 8;
        graceTurns = 10;
      };
      description = "pi-subagents global configuration.";
    };

    rtkOptimizer = lib.mkOption {
      type = lib.types.attrs;
      default = {
        enabled = true;
        mode = "rewrite";
        guardWhenRtkMissing = true;
        showRewriteNotifications = true;
        outputCompaction = {
          enabled = true;
          stripAnsi = true;
          readCompaction = {
            enabled = false;
          };
          sourceCodeFilteringEnabled = false;
          preserveExactSkillReads = true;
          sourceCodeFiltering = "none";
          aggregateTestOutput = true;
          filterBuildOutput = true;
          compactGitOutput = true;
          aggregateLinterOutput = true;
          groupSearchOutput = true;
          trackSavings = true;
          smartTruncate = {
            enabled = false;
            maxLines = 220;
          };
          truncate = {
            enabled = true;
            maxChars = 12000;
          };
        };
      };
      description = "pi-rtk-optimizer extension configuration.";
    };

    telegram = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "pi-telegram bridge configuration.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      cfg.package
      pkgs.python314Packages.ddgs
      pkgs.tesseract
      kreuzberg-cli
    ];

    home.file = {
      ".pi/agent/settings.json" = lib.mkIf (cfg.settings != { }) {
        text = builtins.toJSON (
          lib.filterAttrsRecursive (_: v: v != null && v != [ ] && v != { }) cfg.settings
        );
      };

      ".pi/agent/extensions/search.json" = lib.mkIf (cfg.search != { }) {
        text = builtins.toJSON cfg.search;
      };

      ".pi/agent/extensions/pi-permission-system/config.json" = {
        text = builtins.toJSON cfg.permissionSystem;
      };

      ".pi/agent/pi-permissions.jsonc" = {
        text = builtins.toJSON cfg.permissions;
      };

      ".pi/agent/subagents.json" = {
        text = builtins.toJSON cfg.subagents;
      };

      ".pi/agent/extensions/pi-rtk-optimizer/config.json" = {
        text = builtins.toJSON cfg.rtkOptimizer;
      };

      ".pi/agent/telegram.json" = lib.mkIf (cfg.telegram != { }) {
        text = builtins.toJSON cfg.telegram;
      };
    };

    xdg.configFile."mcp/mcp.json" = lib.mkIf (cfg.mcp != { }) {
      text = builtins.toJSON cfg.mcp;
    };
  };
}
