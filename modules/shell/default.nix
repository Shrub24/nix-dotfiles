{ config, inputs, ... }:
let
  omniroute = inputs.nix-fleet.lib.serviceEndpoints.url config.fleet {
    service = "omniroute";
    endpoint = "api";
    via = "tailnet";
  };
in
{
  flake.modules.homeManager.shell =
    {
      config,
      pkgs,
      ...
    }:
    let
      # Image preview: only icat's unicode placeholders survive fzf's repaint (in
      # kitty-family terminals); elsewhere chafa picks the format, symbols as fallback.
      previewImage = pkgs.writeShellScript "preview-image" ''
        set -o pipefail

        cols=''${FZF_PREVIEW_COLUMNS:-80}
        rows=''${FZF_PREVIEW_LINES:-40}

        if test -n "''${KITTY_WINDOW_ID:-}" ||
          test -n "''${KITTY_PID:-}" ||
          test -n "''${KITTY_LISTEN_ON:-}" ||
          test -n "''${HERDR_PANE_ID:-}"; then
          # --clear drops the previous placement; the trailing reset code arrives
          # without a newline (fzf reads it as a scroll offset), so it is folded on.
          if ! {
            command -v kitten >/dev/null 2>&1 &&
            kitten icat --clear --transfer-mode=memory --unicode-placeholder \
              --stdin=no --place="''${cols}x''${rows}@0x0" "$1" \
              | sed '$d' | sed $'$s/$/\e[m/'
          }; then
            chafa -f symbols --size="''${cols}x''${rows}" "$1"
            echo
          fi
        else
          chafa --size="''${cols}x''${rows}" "$1"
          echo
        fi
      '';
    in
    {
      home = {
        packages = with pkgs; [
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
          "${config.home.homeDirectory}/.local/bin"
          "${config.home.homeDirectory}/.local/share/pnpm/bin"
          "${config.home.homeDirectory}/.bun/bin"
        ];

        sessionVariables = {
          NIX_PATH = "nixpkgs=flake:nixpkgs";
          UV_TOOL_PYTHON_PREFERENCE = "only-managed";
          # clone (reflink) is the only mode that survives a btrfs subvolume boundary;
          # the default hardlink silently falls back to a full copy for every venv.
          UV_LINK_MODE = "clone";
          # Same cross-subvolume story for Aube; clone uses reflinks, matching uv.
          AUBE_PACKAGE_IMPORT_METHOD = "clone";
          QMD_EMBED_MODEL = "hf://Qwen/Qwen3-Embedding-0.6B-GGUF/Qwen3-Embedding-0.6B-f16.gguf";
          PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
          BUN_INSTALL = "${config.home.homeDirectory}/.bun";
          GITHUB_USERNAME = "Shrub24";
          EDITOR = "nvim";
          LESS = "-R --use-color";
          BAT_THEME = "noctalia";
          OMNIROUTE_BASE_URL = omniroute;
          OPENCODE_EXPERIMENTAL_BACKGROUND_SUBAGENTS = true;
          # pi-cache-optimizer: keep prompts/skill XML verbatim.
          PI_CACHE_OPTIMIZER_NO_PROMPT_REWRITE = "1";
          PI_CACHE_OPTIMIZER_NO_SKILL_COMPRESSION = "1";
          PI_CACHE_RETENTION = "long";
        };
      };

      programs = {
        bash.enable = true;

        bat.enable = true;

        broot.enable = true;

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
              command = ''"${previewImage}" "%pistol-filename%"'';
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
