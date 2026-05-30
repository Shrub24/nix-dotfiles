{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  abbr = import ./abbr.nix;
in
{
  programs.fish = {
    enable = true;
    functions = {
      _fzf_preview_router = ''
        set -l cand $argv[1]
        set -l cmd_buffer $argv[2]

        # Route 1: It's a Subcommand or Flag (Does not exist on disk)
        if not test -e "$cand"; and not test -L "$cand"
          
          # Ask Fish what the next level of flags are
          set -l comps (complete -C "$cmd_buffer $cand " 2>/dev/null)
          
          if test -n "$comps"
            echo "$comps" | sed 's/\t/  /g' | column -t | bat -p --color=always
            return
          end

          # TLDR Fallback for dead-end commands
          set -l base_cmd (string split " " -- $cand)[1]
          if command -v tldr >/dev/null
            tldr --color=always "$cand" 2>/dev/null; or tldr --color=always "$base_cmd" 2>/dev/null
          end
          return
        end

        pistol "$cand"
      '';
      _fzf_complete_lookahead = ''
        set -l cmd_buffer (commandline -cp)

        if test -z "$cmd_buffer"
          return
        end

        set -l fzf_out (complete -C "$cmd_buffer " | fzf \
          --layout=reverse \
          --height=50% \
          --ansi \
          --tiebreak=index \
          --preview "_fzf_preview_router {1} \"$cmd_buffer\"" \
          --preview-window="right:55%:wrap"
        )

        if test -n "$fzf_out"
          set -l selection (string split \t -- $fzf_out)[1]
          commandline -i "$selection "
        end

        commandline -f repaint
      '';
    };

    plugins = with pkgs.fishPlugins; [
      {
        name = "tide";
        src = tide.src;
      }
      {
        name = "fzf-fish";
        src = fzf-fish.src;
      }
      {
        name = "plugin-git";
        src = plugin-git.src;
      }
      {
        name = "puffer";
        src = puffer.src;
      }
      {
        name = "autopair";
        src = inputs.fish-autopair;
      }
      {
        name = "done";
        src = inputs.fish-done;
      }
      {
        name = "sponge";
        src = inputs.fish-sponge;
      }
      # {
      #   name = "fifc";
      #   src = inputs.fish-fifc;
      # }
      {
        name = "fish-ai";
        src = inputs.fish-ai;
      }
      {
        name = "replay-fish";
        src = inputs.fish-replay;
      }
      {
        name = "fish-abbreviation-tips";
        src = inputs.fish-abbreviation-tips;
      }
    ];

    shellInit = ''
      if test -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.fish
      end

      fish_add_path --append /usr/local/bin /usr/bin /bin /usr/sbin /sbin

      set -gx FZF_DEFAULT_COMMAND 'fd -LH --exclude .git'
      set -gx FZF_DEFAULT_OPTS "--bind=tab:accept --layout=reverse --height=~75% --style=full --tiebreak=index \
        --ansi --border=rounded --highlight-line --info=inline-right \
        --color=bg:-1,bg+:0,fg:-1,fg+:-1,gutter:-1,border:4,scrollbar:4 \
        --color=hl:4,hl+:4,header:3,separator:3,info:5,marker:5,pointer:5,spinner:5,prompt:4,query:7:regular"
    '';

    interactiveShellInit = ''
      set -g fish_greeting ""

      set -g -x fish_autosuggestion_enabled 1

      if test -f "$HOME/.config/sops-nix/secrets/rendered/zsh-secrets.env"
        replay "set -a; source $HOME/.config/sops-nix/secrets/rendered/zsh-secrets.env; set +a"
      end

      # fancy ctrl z
      bind \cz 'if jobs -q; fg; else; commandline -f repaint; end'
      bind \cs 'commandline -i "sudo "; commandline -f execute'

      set -gx fzf_history_opts   $FZF_DEFAULT_OPTS
      set -gx fzf_directory_opts $FZF_DEFAULT_OPTS
      set -gx fzf_variables_opts $FZF_DEFAULT_OPTS
      set -gx fzf_processes_opts $FZF_DEFAULT_OPTS

      set fzf_preview_dir_cmd eza --all --color=always
      set fzf_preview_file_cmd bat --color=always --style=numbers

      bind -M insert \t complete-and-search
      bind -M default \t complete-and-search

      # fifc config
      bind -M insert ctrl-space _fzf_complete_lookahead
      bind -M default ctrl-space _fzf_complete_lookahead
      # bind -M insert \t _fifc
      # set -U fifc_fzf_opts $FZF_DEFAULT_OPTS "--height=50% --layout=reverse --border --inline-info"
      # fifc -n 'test -e "$fifc_candidate"' -p 'pistol "$fifc_candidate"'
      # fifc -n 'not test -e "$fifc_candidate"' -p 'complete -C "$fifc_commandline $fifc_candidate" | string replace -r "\t" "  " | column -t | bat -p --color=always'

      # fifc -n 'test -n "$fifc_candidate"' -p 'complete -C "$fifc_commandline $fifc_candidate " | column -c 80'

      fish_vi_key_bindings
      set fish_cursor_default block
      set fish_cursor_insert line
      set fish_cursor_visual block

      set sponge_purge_only_on_exit true

    '';

    shellAbbrs =
      let
        addPosition =
          name: def:
          {
            expansion = def.expansion;
          }
          // lib.optionalAttrs (def.global or false) { position = "anywhere"; };
      in
      lib.mapAttrs addPosition abbr;
  };

  programs.zoxide.enableFishIntegration = true;
  programs.eza.enableFishIntegration = true;
  programs.pay-respects.enableFishIntegration = true;
}
