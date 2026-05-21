{ config, lib, ... }:

{
  programs.zsh = {
    enable = true;
    dotDir = "${config.home.homeDirectory}/.config/zshrc";
    enableCompletion = true;
    zprof.enable = false;
    antidote = {
      enable = true;
      plugins = [
        "getantidote/use-omz"
        "romkatv/powerlevel10k"
        # "ohmyzsh/ohmyzsh path:lib"
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
        # "zsh-users/zsh-completions path:src kind:fpath"
      ];
    };

    autosuggestion = {
      enable = true;
      strategy = [
        "history"
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
      (lib.mkOrder 100 ''
        # Powerlevel10k instant prompt must run before anything that may print.
        if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
          source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
        fi
      '')
      (lib.mkOrder 500 ''
        for f in ~/.config/zshrc/conf.d/*.zsh(N); do
          source "$f"
        done
      '')
      ''
        . "$HOME/.local/bin/env"

        if [[ -t 0 ]]; then
          stty -ixon
        fi

        zstyle ':bracketed-paste-magic' active-widgets '.self-*'

        # Completion cache and matcher
        zstyle ':completion:*' use-cache on
        zstyle ':completion:*' cache-path "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion-cache"
        zstyle ':completion:*' matcher-list \
          'm:{a-z}={A-Za-z}' \
          'r:|[._-]=* r:|=*' \
          'l:|=* r:|=*'
        zstyle ':completion:*' rehash true
        zstyle ':completion:*' squeeze-slashes true
        zstyle ':completion:*' special-dirs true

        # Partial accept autosuggestion: Alt+F accepts one word
        bindkey -M viins '^[f' forward-word

        # Powerlevel10k theme
        [[ ! -f ~/.config/zshrc/.p10k.zsh ]] || source ~/.config/zshrc/.p10k.zsh
      ''
      (lib.mkOrder 2000 ''
        eval "$(direnv-instant hook zsh)"
      '')
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
      "-h"
    ];
  };

  home.sessionPath = [
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
}
