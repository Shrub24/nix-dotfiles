{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./zsh.nix
    ./fish.nix
  ];

  home.packages = with pkgs; [
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
    pistol
  ];

  programs.fzf = {
    enable = true;
    enableFishIntegration = false;
  };
  programs.zoxide.enable = true;
  programs.eza = {
    enable = true;
    icons = "always";
    colors = "always";
    extraOptions = [
      "--group-directories-first"
      "-h"
    ];
  };
  programs.pay-respects.enable = true;

  home.shellAliases = {
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

  home.sessionPath = [
    "${config.home.homeDirectory}/.nix-profile/bin"
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.local/share/pnpm/bin"
    "${config.home.homeDirectory}/.bun/bin"
  ];

  home.sessionVariables = {
    QMD_EMBED_MODEL = "hf://Qwen/Qwen3-Embedding-0.6B-GGUF/Qwen3-Embedding-0.6B-f16.gguf";
    PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
    BUN_INSTALL = "${config.home.homeDirectory}/.bun";
    GITHUB_USERNAME = "Shrub24";
    EDITOR = "nvim";
    LESS = "-R --use-color";
    BAT_THEME = "matugen-bat-colors";
    DOTNET_ROOT = "/usr/bin";
  };

  programs.pistol = {
    enable = true;
    associations = [
      # Text & Code -> Bat (syntax highlighting)
      {
        mime = "text/*";
        command = "bat --color=always %pistol-filename%";
      }
      {
        mime = "application/json";
        command = "bat -l json --color=always %pistol-filename%";
      }
      # Images -> Chafa (high-res block characters for WezTerm)
      {
        mime = "image/*";
        command = "chafa -f symbols --size=80x40 %pistol-filename%";
      }
      # PDFs -> pdftotext -> Bat
      {
        mime = "application/pdf";
        command = "pdftotext %pistol-filename% - | bat -l md --color=always --style=plain";
      }
      # Audio -> Mediainfo
      {
        mime = "audio/*";
        command = "mediainfo %pistol-filename%";
      }
      {
        # Directories
        mime = "inode/directory";
        command = "eza --tree --icons --level=2 --color=always %pistol-filename%";
      }
      {
        # Symlinks
        mime = "inode/symlink";
        # eza -l shows the symlink arrow and target nicely
        command = "eza -l --color=always --icons %pistol-filename%";
      }
      {
        # Sockets, block devices, FIFOs, etc.
        mime = "inode/*";
        command = "file -b %pistol-filename%";
      }
    ];
  };
}
