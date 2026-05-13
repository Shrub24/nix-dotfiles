{
  imports = [
    ./modules/core.nix
    ./modules/nix.nix
    ./modules/direnv.nix
    ./modules/sops.nix
    ./modules/zsh.nix
    ./modules/pi.nix
    ./modules/hermes.nix
  ];

  programs.pi = {
    enable = true;
    settings = {
      theme = "dark";
      quietStartup = false;
      defaultProvider = "minimax";
      defaultModel = "minimax/MiniMax-M2.7";
      defaultThinkingLevel = "medium";
      enabledModels = [
        "minimax/MiniMax-M2.7"
        "minimax/*"
        "openai/gpt-5.4"
        "openai/gpt-5.3-codex"
        "opencode-go/*"
      ];
      packages = [
        "npm:pi-mcp-adapter"
        "npm:pi-multi-pass"
        "/home/saurabhj/Projects/dev/custom/pi-search-multi"
        "npm:pi-observational-memory"
        "npm:pi-permission-system"
        "npm:@tintinweb/pi-subagents"
        "npm:@juicesharp/rpiv-ask-user-question"
        "npm:@juicesharp/rpiv-todo"
        "npm:@juicesharp/rpiv-btw"
        "npm:@aliou/pi-processes"
        "npm:pi-lens"
        "npm:pi-rtk-optimizer"
        "git:github.com/elpapi42/pi-fork"
        "npm:pi-powerline-footer"
        "npm:pi-rewind-hook"
        "npm:pi-vim"
      ];
      "pi-fork" = {
        defaultEffort = "balanced";
        costFooter = true;
        effortProfiles = {
          fast = {
            provider = "opencode-go";
            id = "deepseek-v4-flash";
            thinking = "medium";
          };
          balanced = {
            provider = "minimax";
            id = "minimax-M2.7";
          };
          deep = {
            provider = "opencode-go";
            id = "deepseek-v4-pro";
            thinking = "medium";
          };
        };
      };
      piVim.clipboardMirror = "yank";
    };
    mcp = {
      settings = {
        toolPrefix = "server";
        idleTimeout = 10;
        directTools = false;
      };
      mcpServers = {
        context7 = {
          command = "pnpx";
          args = [
            "@upstash/context7-mcp"
            "--api-key"
            "\${CONTEXT7_API_KEY}"
          ];
        };
        gh-grep = {
          url = "https://mcp.grep.app";
        };
        semgrep = {
          command = "semgrep";
          args = [ "mcp" ];
        };
        desktop-commander = {
          command = "pnpx";
          args = [ "@wonderwhy-er/desktop-commander@latest" ];
        };
        jina-reader = {
          url = "https://mcp.jina.ai/v1?include_tools=read_url,extract_pdf,parallel_read_url";
          headers = {
            Authorization = "Bearer \${JINA_TOKEN}";
          };
        };
        github = {
          url = "https://api.githubcopilot.com/mcp/";
          headers = {
            Authorization = "Bearer \${GITHUB_PAT}";
          };
        };
        markdownify = {
          command = "node";
          args = [ "/home/saurabhj/Projects/dev/tools/markdownify-mcp/dist/index.js" ];
          env = {
            UV_PATH = "/home/saurabhj/.local/bin/uv";
          };
        };
        nixos = {
          command = "uvx";
          args = [ "mcp-nixos" ];
        };
      };
    };
    search = {
      defaultBackend = "auto";
      backends = {
        tavily = {
          enabled = true;
          apiKey = "TAVILY_API_KEY";
        };
        brave = {
          enabled = true;
          apiKey = "BRAVE_API_KEY";
        };
        firecrawl = {
          enabled = true;
          apiKey = "FIRECRAWL_API_KEY";
        };
      };
    };
    permissions = {
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
      mcp = {
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
        "desktop-commander:*kill*" = "ask";
        "desktop-commander:*terminate*" = "ask";
        "desktop-commander:*force*" = "ask";
        desktop_commander = "ask";
      };
    };
  };

  programs.hermes = {
    enable = true;
    settings = {
      model = {
        default = "anthropic/claude-sonnet-4";
      };
    };
    mcpServers = {
      context7 = {
        command = "pnpx";
        args = [
          "@upstash/context7-mcp"
          "--api-key"
          "\${CONTEXT7_API_KEY}"
        ];
      };
      desktop-commander = {
        command = "pnpx";
        args = [
          "@wonderwhy-er/desktop-commander@latest"
        ];
      };
      jina-reader = {
        url = "https://mcp.jina.ai/v1?include_tools=read_url,extract_pdf,parallel_read_url";
        headers = {
          Authorization = "Bearer \${JINA_TOKEN}";
        };
      };
      github = {
        url = "https://api.githubcopilot.com/mcp/";
        headers = {
          Authorization = "Bearer \${GITHUB_PAT}";
        };
      };
      semgrep = {
        command = "semgrep";
        args = [ "mcp" ];
      };
      nixos = {
        command = "uvx";
        args = [ "mcp-nixos" ];
      };
      markdownify = {
        command = "node";
        args = [ "/home/saurabhj/Projects/dev/tools/markdownify-mcp/dist/index.js" ];
      };
    };
  };
}
