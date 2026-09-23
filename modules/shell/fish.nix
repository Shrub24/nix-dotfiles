{ inputs, ... }: {
  flake-file.inputs = {
    fish-abbreviation-tips = {
      url = "github:Gazorby/fish-abbreviation-tips";
      flake = false;
    };
    fish-replay = {
      url = "github:jorgebucaran/replay.fish";
      flake = false;
    };
  };

  flake.modules.homeManager.fish =
    {
      lib,
      pkgs,
      ...
    }:

    let
      abbr = import ./_abbr.nix;
    in
    {
      programs = {
        fish = {
          enable = true;
          functions = {
            _fzf_preview_router = ''
              set -l cand $argv[1]
              set -l base_buffer $argv[2]

              if not test -e "$cand"; and not test -L "$cand"
                # We use the clean base_buffer (e.g., "git ") + cand ("commit") + space
                set -l comps (complete -C "$base_buffer "(string escape -- "$cand") 2>/dev/null)

                if test -n "$comps"
                  echo "$comps" | sed 's/\t/  /g' | column -t | bat -p --color=always
                  return
                end

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

              # 1. Identify the exact token we are currently typing (e.g., "$S" or "commi")
              set -l current_token (commandline -ct)

              # 2. Extract the "Base Context" by subtracting the token from the end of the buffer.
              set -l token_len (string length -- "$current_token")
              set -l buf_len (string length -- "$cmd_buffer")
              set -l cut_pos (math $buf_len - $token_len)

              set -l base_buffer ""
              if test $cut_pos -gt 0
                set base_buffer (string sub -l $cut_pos -- "$cmd_buffer")
              end

              # 3. Launch FZF
              set -l fzf_raw (complete -C "$cmd_buffer" | fzf \
                --delimiter="\t" \
                --query=(string unescape -- "$current_token") \
                --expect=right \
                --preview "_fzf_preview_router '{1}' \"$base_buffer\"" \
                --preview-window="right:55%:wrap" | string collect)

              if test -z "$fzf_raw"
                return
              end

              set -l fzf_out (string split \n -- "$fzf_raw")
              set -l key $fzf_out[1]
              set -l raw_selection $fzf_out[2]

              if test -n "$raw_selection"
                set -l selection (string split \t -- $raw_selection)[1]

                commandline -t -- (string escape -- "$selection")

                if test "$key" = "right"
                  if not string match -q "*/" "$selection"
                    commandline -i " "
                  end
                  # Recurse instantly for continuous navigation
                  _fzf_complete_lookahead
                else
                  if not string match -q "*/" "$selection"
                    commandline -i " "
                  end
                end
              end

              commandline -f repaint
            '';

          };

          plugins = with pkgs.fishPlugins; [
            {
              name = "tide";
              inherit (tide) src;
            }
            {
              name = "fzf-fish";
              inherit (fzf-fish) src;
            }
            {
              name = "plugin-git";
              inherit (plugin-git) src;
            }
            {
              name = "puffer";
              inherit (puffer) src;
            }
            {
              name = "autopair";
              inherit (autopair) src;
            }
            {
              name = "done";
              inherit (done) src;
            }
            {
              name = "sponge";
              inherit (sponge) src;
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
          '';

          interactiveShellInit = ''
            set -g fish_greeting ""

            set -g -x fish_autosuggestion_enabled 1

            if test -f "$HOME/.config/sops-nix/secrets/rendered/agent-env.env"
              replay "set -a; source $HOME/.config/sops-nix/secrets/rendered/agent-env.env; set +a"
            end

            # fancy ctrl z + sudo
            bind \cz 'if jobs -q; fg; else; commandline -f repaint; end'
            bind \cs 'commandline -i "sudo "; commandline -f execute'

            set fzf_preview_dir_cmd eza --all --color=always
            set fzf_preview_file_cmd bat --color=always --style=numbers
            set fzf_diff_highlighter delta --paging=never --width=20

            # Noctalia's fzf palette is rendered as a POSIX file. Two traps
            # here, both hit in practice:
            #
            # 1. Sourcing the fish variant instead would write FZF_DEFAULT_OPTS
            #    through `set -Ux`, so every session re-appends the palette and
            #    the variable grows without bound.
            #
            # 2. Even via the POSIX file, the palette renders as MULTILINE
            #    text. Command substitution turns each line into a fish list
            #    element, and an exported list var in that shape makes every
            #    later exec in the shell fail with fish's "argument or exported
            #    variable exceeds the OS argument length limit" — the snacks
            #    terminal, zoxide, mise, everything. Flattening to one line
            #    (tr) is what makes it safe.
            #
            # The guard stops re-appends in nested shells (kitty windows,
            # herdr panes, snacks terminals all inherit and re-run this), which
            # is how the variable accumulated 15 palette copies before.
            if test -f "$XDG_CONFIG_HOME/fzf/themes/noctalia.sh"; and not string match -q -- '*bg+:*' -- $FZF_DEFAULT_OPTS
              set -gx FZF_DEFAULT_OPTS "$FZF_DEFAULT_OPTS "(
                sh -c 'FZF_DEFAULT_OPTS=; . "$XDG_CONFIG_HOME/fzf/themes/noctalia.sh"; printf %s "$FZF_DEFAULT_OPTS"' | tr '\n' ' '
              )
            end

            bind -M insert \t complete-and-search
            bind -M default \t complete-and-search

            # ctrl-space: custom fzf lookahead completion
            bind -M insert ctrl-space _fzf_complete_lookahead
            bind -M default ctrl-space _fzf_complete_lookahead

            fish_vi_key_bindings
            set fish_cursor_default block
            set fish_cursor_insert line
            set fish_cursor_visual block

            set sponge_purge_only_on_exit true

          '';

          shellAbbrs =
            let
              addPosition =
                _: def:
                {
                  inherit (def) expansion;
                }
                // lib.optionalAttrs (def.global or false) { position = "anywhere"; };
            in
            lib.mapAttrs addPosition abbr;
        };

        zoxide.enableFishIntegration = true;
        eza.enableFishIntegration = true;
        "pay-respects".enableFishIntegration = true;
      };

      xdg.configFile."fish/completions/hermes.fish".source =
        pkgs.runCommand "hermes-fish-completions" { }
          ''
            ${
              inputs.hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
            }/bin/hermes completion fish > $out
          '';
    }

  ;
}
