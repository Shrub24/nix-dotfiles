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
          jaq
          jq
          yq
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
          # Keep the zero-price override off too, so enabling cacheWarming in /settings cannot start keep-alive refreshes.
          PI_CACHE_OPTIMIZER_NO_ZERO_PRICE_WARMING = "1";
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
          # fzf's own walker replaces `fd` here: it lists files and directories, follows
          # symlinks and includes hidden entries, and fzf picks the path scoring scheme
          # for it automatically. Skips are the build and cache trees worth never seeing.
          defaultOptions = [
            "--walker=file,dir,follow,hidden"
            "--walker-skip=.git,.jj,node_modules,.direnv,result,target,__pycache__,.venv"
            # One word: Home Manager joins defaultOptions with spaces into
            # FZF_DEFAULT_OPTS, which fzf splits on whitespace, so a value with a
            # space becomes a stray argument. Richer ghost text belongs in a
            # command that passes its own argv.
            "--ghost=filter"
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
          # The palette is rendered by the noctalia aspect into
          # ~/.config/fzf/themes/noctalia.opts, which the shells point
          # FZF_DEFAULT_OPTS_FILE at; colours live there, not here, because an
          # environment value would outrank the file.
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
      };
    };
}
