_: {
  flake.modules.homeManager.shell =
    {
      config,
      pkgs,
      ...
    }:

    {
      home = {
        packages = with pkgs; [
          bat
          duf
          procs
          bottom
          dust
          sd
          fd
          ripgrep
          jq
          yq
          chafa
          mediainfo
          poppler-utils
        ];

        shellAliases = {
          nano = "nvim";
          edit = "nvim";
          vim = "nvim";
          vi = "nvim";
          "..." = "../..";
          "...." = "../../..";
          df = "duf";
          du = "dust";
          cat = "bat";
          sed = "sd";
          ps = "procs";
          top = "btm";
          htop = "btop";
        };

        sessionPath = [
          "${config.home.homeDirectory}/.nix-profile/bin"
          "${config.home.homeDirectory}/.local/bin"
          "${config.home.homeDirectory}/.local/share/pnpm/bin"
          "${config.home.homeDirectory}/.bun/bin"
        ];

        sessionVariables = {
          NIX_PATH = "nixpkgs=flake:nixpkgs";
          UV_TOOL_PYTHON_PREFERENCE = "only-managed";
          QMD_EMBED_MODEL = "hf://Qwen/Qwen3-Embedding-0.6B-GGUF/Qwen3-Embedding-0.6B-f16.gguf";
          PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
          BUN_INSTALL = "${config.home.homeDirectory}/.bun";
          GITHUB_USERNAME = "Shrub24";
          EDITOR = "nvim";
          LESS = "-R --use-color";
          BAT_THEME = "matugen-bat-colors";
          OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS = true;
        };
      };

      programs = {
        fzf = {
          enable = true;
          enableFishIntegration = false;
          defaultCommand = "fd -LH --exclude .git";
          defaultOptions = [
            "--layout=reverse"
            "--height=~75%"
            "--min-height=10+"
            "--style=default"
            "--tiebreak=index"
            "--ansi"
            "--border=rounded"
            "--highlight-line"
            "--info=inline-right"
            "--color=bg:-1,bg+:0,fg:-1,fg+:-1,gutter:-1,border:4,scrollbar:4"
            "--color=hl:4,hl+:4,header:3,separator:3,info:5,marker:5,pointer:5,spinner:5,prompt:4,query:7:regular"
          ];
        };
        zoxide.enable = true;
        eza = {
          enable = true;
          icons = "always";
          colors = "always";
          extraOptions = [
            "--group-directories-first"
            "-h"
          ];
        };
        "pay-respects".enable = true;
        pistol = {
          enable = true;
          associations = [
            {
              mime = "text/*";
              command = "bat --color=always %pistol-filename%";
            }
            {
              mime = "application/json";
              command = "bat -l json --color=always %pistol-filename%";
            }
            {
              mime = "image/*";
              command = "chafa -f symbols --size=80x40 %pistol-filename%";
            }
            {
              mime = "application/pdf";
              command = "pdftotext %pistol-filename% - | bat -l md --color=always --style=plain";
            }
            {
              mime = "audio/*";
              command = "mediainfo %pistol-filename%";
            }
            {
              mime = "inode/directory";
              command = "eza --tree --icons --level=2 --color=always %pistol-filename%";
            }
            {
              mime = "inode/symlink";
              command = "eza -l --color=always --icons %pistol-filename%";
            }
            {
              mime = "inode/*";
              command = "file -b %pistol-filename%";
            }
          ];
        };
      };
    }

  ;
}
