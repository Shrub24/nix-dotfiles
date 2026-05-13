{ config, lib, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = "${config.home.homeDirectory}/.config/zshrc";

    antidote = {
      enable = true;
      plugins = [
        "getantidote/use-omz"
        "romkatv/powerlevel10k"
        "ohmyzsh/ohmyzsh path:lib"
        "ohmyzsh/ohmyzsh path:plugins/dirhistory"
        "ohmyzsh/ohmyzsh path:plugins/copybuffer"
        "ohmyzsh/ohmyzsh path:plugins/copyfile"
        "ohmyzsh/ohmyzsh path:plugins/copypath"
        "ohmyzsh/ohmyzsh path:plugins/extract"
        "ohmyzsh/ohmyzsh path:plugins/fancy-ctrl-z"
        "ohmyzsh/ohmyzsh path:plugins/gitignore"
        "ohmyzsh/ohmyzsh path:plugins/sudo"
        "ohmyzsh/ohmyzsh path:plugins/git"
        "ohmyzsh/ohmyzsh path:plugins/jsontools"
        "ohmyzsh/ohmyzsh path:plugins/ssh"
        "Aloxaf/fzf-tab"
        "Freed-Wu/fzf-tab-source"
        "jeffreytse/zsh-vi-mode"
        "zsh-users/zsh-completions path:src kind:fpath"
        "MichaelAquilina/zsh-you-should-use"
      ];
    };

    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };

    syntaxHighlighting.enable = true;

    history = {
      size = 50000;
      save = 50000;
      path = "${config.home.homeDirectory}/.config/zshrc/.zsh_history";
      extended = true;
      expireDuplicatesFirst = true;
      findNoDups = true;
      ignoreAllDups = true;
      ignoreDups = true;
      ignoreSpace = true;
      saveNoDups = true;
      share = true;
    };

    setOptions = [
      "GLOB_DOTS"
      "INTERACTIVE_COMMENTS"
    ];

    shellAliases = {
      "nano" = "nvim";
      "edit" = "nvim";
      "vim" = "nvim";
      "vi" = "nvim";
      "tree" = "eza --tree --level=2 --color=always --group-directories-first --icons";
      "cat" = "bat";
      "df" = "duf";
      "..." = "../..";
      "...." = "../../..";
    };

    envExtra = ''
      export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30
      export ZSH_AUTOSUGGEST_USE_ASYNC=1
      if [ -f "$HOME/.secrets/zsh-secrets.env" ]; then
        set -a
        source "$HOME/.secrets/zsh-secrets.env"
        set +a
      fi
    '';

    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        for f in ~/.config/zshrc/conf.d/*.zsh(N); do
          source "$f"
        done
      '')
      ''
        # Powerlevel10k instant prompt (must be near top)
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi

        . "$HOME/.local/bin/env"

        if [[ -t 0 ]]; then
          stty -ixon
        fi

        zstyle ':bracketed-paste-magic' active-widgets '.self-*'

        # Powerlevel10k theme
        [[ ! -f ~/.config/zshrc/.p10k.zsh ]] || source ~/.config/zshrc/.p10k.zsh
      ''
    ];
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.pay-respects = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "always";
    colors = "always";
    extraOptions = [
      "--group-directories-first"
      "-l"
    ];
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.local/share/pnpm"
    "${config.home.homeDirectory}/.bun/bin"
  ];

  home.sessionVariables = {
    GITHUB_USERNAME = "Shrub24";
    EDITOR = "nvim";
    LESS = "-R --use-color";
    BAT_THEME = "matugen-bat-colors";
    DOTNET_ROOT = "/usr/bin";
    PNPM_HOME = "${config.home.homeDirectory}/.local/share/pnpm";
    BUN_INSTALL = "${config.home.homeDirectory}/.bun";
    NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.local";
  };

  home.file.".npmrc".text = ''
    prefix=${config.home.homeDirectory}/.local
  '';
}
