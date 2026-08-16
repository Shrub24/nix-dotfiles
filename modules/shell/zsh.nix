_: {
  flake.modules.homeManager.zsh =
    { config, lib, ... }:

    let
      abbrDefs = import ./_abbr.nix;
      isGlobal = _: def: def.global or false;
      regular = lib.filterAttrs (name: def: !isGlobal name def) abbrDefs;
    in

    {
      programs = {
        zsh = {
          enable = true;
          dotDir = "${config.home.homeDirectory}/.config/zshrc";
          enableCompletion = true;
          zprof.enable = false;
          antidote = {
            enable = true;
            plugins = [
              "getantidote/use-omz"
              "romkatv/powerlevel10k"
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
            ];
          };

          autosuggestion = {
            enable = true;
            strategy = [ "history" ];
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

          envExtra = ''
            case ":''${PATH}:" in
              *:"$HOME/.nix-profile/bin":*) ;;
              *) export PATH="$HOME/.nix-profile/bin:''${PATH}" ;;
            esac

            export ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=30
            export ZSH_AUTOSUGGEST_USE_ASYNC=1
            if [ -f "$HOME/.config/sops-nix/secrets/rendered/zsh-secrets.env" ]; then
              set -a
              source "$HOME/.config/sops-nix/secrets/rendered/zsh-secrets.env"
              set +a
            fi
          '';

          initContent = lib.mkMerge [
            (lib.mkOrder 100 ''
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

              zstyle ':completion:*' use-cache on
              zstyle ':completion:*' cache-path "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completion-cache"
              zstyle ':completion:*' matcher-list \
                'm:{a-z}={A-Za-z}' \
                'r:|[._-]=* r:|=*' \
                'l:|=* r:|=*'
              zstyle ':completion:*' rehash true
              zstyle ':completion:*' squeeze-slashes true
              zstyle ':completion:*' special-dirs true

              bindkey -M viins '^[f' forward-word

              [[ ! -f ~/.config/zshrc/.p10k.zsh ]] || source ~/.config/zshrc/.p10k.zsh
            ''
            (lib.mkOrder 2000 ''
              eval "$(direnv-instant hook zsh)"
            '')
          ];

          zsh-abbr = {
            enable = true;
            abbreviations = lib.mapAttrs (_: def: def.expansion) regular;
          };
        };

        fzf.enableZshIntegration = true;
        zoxide.enableZshIntegration = true;
        "pay-respects".enableZshIntegration = true;
        eza.enableZshIntegration = true;
      };
    }

  ;
}
