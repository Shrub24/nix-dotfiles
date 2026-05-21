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

  # Permission defaults that survive user partial overrides via recursiveUpdate
  defaultPermissions = {
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
      pi_web_search = "allow";
      recall = "allow";
      fork = "allow";
      Agent = "allow";
      get_subagent_result = "allow";
      steer_subagent = "allow";
      mcp = "allow";
      lsp_navigation = "allow";
      ast_grep_search = "allow";
      grep = "allow";
      find = "allow";
      ls = "allow";
      write = "allow";
      bash = "allow";
      ast_grep_replace = "allow";
      cymbal_map = "allow";
      cymbal_search = "allow";
      cymbal_outline = "allow";
      cymbal_show = "allow";
      cymbal_refs = "allow";
      cymbal_impact = "allow";
      cymbal_importers = "allow";
      cymbal_impls = "allow";
      cymbal_investigate = "allow";
      cymbal_trace = "allow";
      cymbal_context = "allow";
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
      "cd *" = "allow";
      "latexmk *" = "allow";
      "code *" = "allow";
      "openspec *" = "allow";
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
    skills = {
      "*" = "allow";
    };
    special = {
      external_directory = "ask";
      doom_loop = "ask";
    };
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
      default = defaultPermissions;
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
      pkgs.maple-mono.NF-unhinted
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
        text = builtins.toJSON (lib.recursiveUpdate defaultPermissions cfg.permissions);
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

      # ── Telegram secret bootstrap (YAML sops, one-shot) ─────────────
      ".pi/agent/prompts/effective.md".text = ''
        ---
        description: Inject main-agent delegation and tool-use discipline
        argument-hint: "[focus: explore|research|author|document]"
        ---
        You are a coding agent. Follow these principles:

        ## Delegation
        - Delegate token-heavy reads, writes, exploration, and research to **ephemeral fork agents**
        - Use `fork` with `effort: "balanced"` for typical work; `effort: "fast"` for simple lookups; `effort: "deep"` for complex design/review
        - Forks return dense, concrete output — let them gather, you summarize
        - For parallel work, launch multiple forks and `get_subagent_result`
        - The `Explore` subagent is read-only and fast — use it for codebase searches
        - The `Plan` subagent handles architecture and planning — use it before large changes

        ## Code Exploration (prefer in order)
        1. `semble` MCP — fastest code search, ~98% fewer tokens than grep+read
        2. `cymbal_*` tools — symbol-level navigation, references, impact analysis
        3. `gh-grep` MCP — GitHub-wide full-text search
        4. `rg` (ripgrep via bash) — local regex search
        5. `lsp_navigation` — IDE-level definitions, references, call hierarchy
        6. `grep`/`find`/`read` — fallback text search

        ## SOTA MCPs (use aggressively)
        - `nixos` MCP for nixpkgs packages, options, and nix language queries
        - `github` MCP for repos, pull requests, issues, code search
        - `desktop-commander` MCP for terminal, file system, and process management
        - `context7` MCP for up-to-date library documentation
        - `markdownify` MCP for web-to-markdown conversion

        ## Pi Plugins
        - `pi-search-multi` for web search (duckduckgo, brave, tavily backends)
        - `pi-cymbal` for codebase-level symbol index and analysis
        - `pi-vim` for clipboard yank operations
        - `pi-permission-system` for security policy

        ## Code Writing
        - **Read first**: study surrounding code with `cymbal_outline`, `cymbal_show`, and `read`
        - **Match patterns**: follow existing conventions, naming, and project structure
        - **Minimal changes**: use `edit` for targeted replacements; `write` only for new files
        - **Idiomatic**: use modern language features appropriate to the project
        - **Check**: run `lsp_diagnostics` after changes; use `nixfmt` for nix files
        - **Never mark a task completed** if tests fail, implementation is partial, or errors persist

        ## Communication
        - Ask clarifying questions when requirements are underspecified (use `ask_user_question`)
        - Be concise in responses
        - Show file paths clearly when working with files
        - Report blockers immediately, do not silently retry
      '';
      ".pi/agent/skills/explore/SKILL.md".text = ''
        ---
        name: explore
        description: Explore and understand codebases using SOTA tools. Use when the user asks to investigate, understand, or map out code, architecture, or dependencies.
        ---

        Explore codebases efficiently using the best available tools.

        **Primary tools (in order of preference):**
        - `semble` MCP (fast code search, ~98% fewer tokens than grep+read)
        - `cymbal_map`, `cymbal_search`, `cymbal_outline`, `cymbal_show`, `cymbal_refs`, `cymbal_importers`, `cymbal_impls` for symbol-level navigation
        - `gh-grep` MCP for GitHub-wide full-text search
        - `rg` (ripgrep) for local regex search, `lsp_navigation` for IDE-level code intelligence

        **Delegation:**
        - For token-heavy reads, offload exploration to an ephemeral `Explore` subagent or a `fork` (balanced effort)
        - Let the subagent return dense, concrete findings with file paths and line numbers
        - Use `run_in_background: true` + `get_subagent_result` for parallel exploration

        **Behavior:**
        - Before reading whole files, outline them with `cymbal_outline` or `ls`/`find`
        - Prefer targeted reads over full-file reads
        - Ask clarifying questions when the scope is ambiguous
        - Report findings concisely with absolute paths
      '';

      ".pi/agent/skills/research/SKILL.md".text = ''
        ---
        name: research
        description: Research topics, APIs, libraries, and technical decisions. Use when the user asks to research, find, look up, or compare technologies.
        ---

        Research topics using the best available search and MCP tools.

        **Primary tools:**
        - `web_search` for up-to-date information, documentation, and facts
        - `jina-reader` MCP for fetching and reading web pages
        - `github` MCP for searching repos, issues, PRs, and code on GitHub
        - `nixos` MCP for querying nixpkgs packages, options, and versions

        **Delegation:**
        - Delegate broad research tasks to ephemeral forks (balanced effort)
        - For multi-source research, launch parallel background forks and merge results
        - Each fork should return dense, citation-backed findings

        **Behavior:**
        - When package versions or APIs are needed, verify with authoritative sources
        - Prefer nixos MCP over web_search for nix-specific queries
        - Cite sources with URLs
        - Ask clarifying questions when research scope is vague
      '';

      ".pi/agent/skills/author/SKILL.md".text = ''
        ---
        name: author
        description: Author, edit, and refactor code or prose. Use when the user asks to write, create, add, fix, refactor, or compose.
        ---

        Write minimal, idiomatic, modern code or clear prose that follows existing patterns.

        ## Before writing (code or prose)
        - Read surrounding files to understand existing patterns, conventions, and style
        - Use `cymbal_outline` and `cymbal_show` to study nearby symbols
        - Ask clarifying questions when requirements are underspecified (use `ask_user_question`)
        - Check with `lsp_diagnostics` before and after code changes

        ## Code vs Prose

        ### Writing code
        - Match the project's existing conventions (naming, structure, formatting)
        - Write minimal changes — do not refactor unrelated code
        - Use modern language features appropriate to the project's target version
        - Keep edits targeted; use `edit` for precise replacements, `write` only for new files
        - Run `lsp_diagnostics` after changes; use `nixfmt` for nix files, `ruff` for python

        ### Writing prose (docs, READMEs, comments, commit messages)
        - Match existing documentation tone and conventions
        - Be concise; prefer examples and code snippets over verbose explanations
        - Use active voice; address the reader directly
        - Show absolute file paths when referencing files
        - For long-form prose, delegate to an ephemeral fork (balanced effort)

        ## Delegation
        - Delegate large code refactors or multi-file changes to ephemeral forks (balanced/deep effort)
        - Delegate long-form prose/documentation to ephemeral forks
        - For simple mechanical edits, use `fast` effort forks
        - Forks return dense, concrete output — let them gather, you summarize

        ## Quality gates
        - Run `lsp_diagnostics` after code changes to catch errors
        - Verify changes build before marking tasks complete
        - Never mark a task completed if tests fail, implementation is partial, or errors persist
      '';

      ".pi/agent/skills/document/SKILL.md".text = ''
        ---
        name: document
        description: Generate documentation, READMEs, and docstrings. Use when the user asks to document, explain, or generate docs.
        ---

        Generate clear, concise documentation.

        **Before documenting:**
        - Read the code being documented with `cymbal_show`
        - Understand existing documentation patterns in the project
        - Ask clarifying questions about audience, format, and scope

        **Delegation:**
        - Delegate large documentation tasks to ephemeral forks
        - Use parallel forks for documenting multiple modules

        **Style:**
        - Match existing doc conventions (JSDoc, docstrings, markdown, etc.)
        - Keep docs concise; prefer examples over verbose explanations
        - Use absolute file paths in references
      '';
    };

    xdg.configFile = {
      "mcp/mcp.json" = lib.mkIf (cfg.mcp != { }) {
        text = builtins.toJSON cfg.mcp;
      };

      # Set maple-mono NF unhinted as default monospace font
      "fontconfig/conf.d/60-maple-mono.conf" = {
        text = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
          <fontconfig>
            <alias>
              <family>monospace</family>
              <prefer>
                <family>Maple Mono NF</family>
              </prefer>
            </alias>
            <alias binding="any">
              <family>MapleMono NF</family>
              <family>Maple Mono NF</family>
              <default>
                <family>monospace</family>
              </default>
            </alias>
          </fontconfig>
        '';
      };
    };
  };
}
