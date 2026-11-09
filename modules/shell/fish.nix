{ inputs, ... }:
{
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

  # NixOS owns the login shell and the /etc/shells entry; Home Manager owns the shell's
  # configuration. Both halves are needed to make fish the interactive shell.
  flake.modules.nixos.fish =
    { config, pkgs, ... }:
    {
      programs.fish.enable = true;
      users.users.${config.currentHost.primaryUser.name}.shell = pkgs.fish;
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
          # sd replaces sed only in interactive shells: nix-shell's bash setup
          # calls sed, and a bash alias would hand it sd's syntax.
          shellAliases.sed = "sd";
          functions = {
            # The picker's preview column, in one of three modes: what the candidate
            # unlocks as a complete token (`lookahead`), what the command is for
            # (`help`), or both — the default, which is what a Tab menu wants.
            #
            # `complete -C` needs the trailing space, otherwise fish completes the token
            # itself and every command shows its own name back.
            _fzf_preview_router = ''
              set -l mode both
              if contains -- $argv[1] lookahead help both
                set mode $argv[1]
                set -e argv[1]
              end
              set -l cand $argv[1]
              set -l base_buffer $argv[2]
              # fish expands ~ in a word, not in a variable, so spell it out before
              # asking the filesystem anything about the candidate.
              set -l path (string replace -r '^~(?=/|$)' "$HOME" "$cand")

              # A real file previews as itself whatever the mode asks for.
              if test -e "$path"; or test -L "$path"
                pistol "$path"
                return
              end

              # one space between the words, so `complete -C` sees a real command line
              set -l prompt (string replace -a -r '[[:space:]]+' ' ' -- (string trim -- "$base_buffer $cand"))
              # The pane decides the budget: a fixed line count pushed the completions
              # section out of a short pane, which made `both` look identical to `help`.
              set -l rows 60
              if string match -qr '^[0-9]+$' -- "$FZF_PREVIEW_LINES"
                set rows $FZF_PREVIEW_LINES
              end
              set -l lines $rows
              if test "$mode" = both
                set lines (math "floor($rows / 2)")
              end

              if test "$mode" != lookahead
                # The summary explains the command, not the highlighted word: a
                # subcommand like `status` would otherwise resolve to whatever other
                # program happens to share that name (fish's own `status`, here).
                set -l cmd (string split ' ' -- $prompt)[1]
                set -l summary
                if command -q tldr
                  set summary (tldr --color=always "$cmd" 2>/dev/null | head -n $lines)
                end
                # tldr covers the documented tools; --help covers the rest, and a page
                # that would block is abandoned after two seconds.
                if test -z "$summary"; and type -q -- $cmd
                  set summary (timeout 2 $cmd --help 2>/dev/null | head -n $lines)
                end
                if test -z "$summary"; and command -q man
                  set summary (man -P cat "$cmd" 2>/dev/null | col -b | head -n $lines)
                end
                if test -n "$summary"
                  printf '\033[2m── %s ──\033[0m\n' "$cmd"
                  printf '%s\n' $summary
                end
              end

              if test "$mode" != help; and not string match -q '*/' -- $cand
                set -l lookahead (complete -C "$prompt " 2>/dev/null)
                if test -n "$lookahead"
                  test "$mode" = both; and printf '\n'
                  printf '\033[2m── completions for "%s" ──\033[0m\n' "$prompt"
                  printf '%s\n' $lookahead | sed 's/\t/  /g' | column -t | bat -p --color=always
                end
              end
            '';

            _fzf_complete_lookahead = ''
              set -l cmd_buffer (commandline -cp)

              # Nothing to look ahead from on an empty line — show fish's own pager.
              if test -z "$cmd_buffer"
                commandline -f complete-and-search
                return
              end

              set -l current_token (commandline -ct)

              set -l token_len (string length -- "$current_token")
              set -l buf_len (string length -- "$cmd_buffer")
              set -l cut_pos (math $buf_len - $token_len)

              set -l base_buffer ""
              if test $cut_pos -gt 0
                set base_buffer (string sub -l $cut_pos -- "$cmd_buffer")
              end

              # The inherited --height=~75% is adaptive, so a handful of matches left
              # the preview two lines tall; a fixed height keeps the pane usable.
              set -l fzf_raw (complete -C "$cmd_buffer" | fzf \
                --height=60% \
                --delimiter="\t" \
                --query=(string unescape -- "$current_token") \
                --expect=right \
                --accept-nth=1 \
                --freeze-left=1 \
                --preview "_fzf_preview_router both '{1}' \"$base_buffer\"" \
                --preview-window="right:55%:wrap" \
                --preview-label="summary + lookahead" \
                # fzf binds tab to toggle+down, which is a no-op without --multi, so
                # the picker has to move the selection itself.
                --bind "tab:down" \
                --bind "btab:up" \
                --bind "ctrl-h:change-preview(_fzf_preview_router help '{1}' \"$base_buffer\")" \
                --bind "ctrl-l:change-preview(_fzf_preview_router lookahead '{1}' \"$base_buffer\")" \
                --bind "ctrl-a:change-preview(_fzf_preview_router both '{1}' \"$base_buffer\")" \
                --bind "ctrl-t:toggle-preview" | string collect)

              if test -z "$fzf_raw"
                return
              end

              set -l fzf_out (string split \n -- "$fzf_raw")
              set -l key $fzf_out[1]
              set -l raw_selection $fzf_out[2]

              if test -n "$raw_selection"
                set -l selection $raw_selection

                # A quoted token cannot be completed into: `complete -C` finds nothing
                # inside `'/some dir/'`, which broke drilling into a directory after the
                # right arrow. So escape with backslashes, never with the quotes
                # `string escape` emits for spaces, and leave a leading ~ bare so it
                # still expands.
                set -l insertion (string replace -ra '([^-_.[:alnum:]/@+~])' '\\\\$1' -- "$selection")
                commandline -t -- $insertion

                if test "$key" = "right"
                  if not string match -q "*/" "$selection"
                    commandline -i " "
                  end
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

          interactiveShellInit = ''
            set -g fish_greeting ""

            set -g -x fish_autosuggestion_enabled 1

            if test -f "$HOME/.config/sops-nix/secrets/rendered/agent-env.fish"
              source "$HOME/.config/sops-nix/secrets/rendered/agent-env.fish"
            end

            bind \cz 'if jobs -q; fg; else; commandline -f repaint; end'
            bind \cs 'commandline -i "sudo "; commandline -f execute'

            # Colours come from the file Noctalia renders into the palette roles the pi
            # theme uses; fzf re-reads it per invocation, so a wallpaper change reaches
            # a running shell. Exporting --color here would outrank the file.
            set -gx FZF_DEFAULT_OPTS_FILE "$XDG_CONFIG_HOME/fzf/themes/noctalia.opts"

            # yazi cannot run an external picker itself — its shell children get no
            # controlling terminal — so the frecency jump opens yazi on the choice
            # instead. `zoxide query -i` is zoxide's own fzf, sized for the terminal.
            # `--cwd-file` makes yazi report where it ended, so the shell follows it
            # and zoxide's PWD hook records the directory actually browsed to:
            # navigation inside yazi is otherwise invisible to the database.
            function yz --description "Open yazi at a frequent directory"
              set -l target (zoxide query -i --exclude $PWD)
              or return 1
              test -n "$target"; or return 1
              set -l cwd_file (command mktemp)
              command yazi --cwd-file=$cwd_file $target
              set -l landed (command cat $cwd_file 2>/dev/null)
              command rm -f $cwd_file
              test -n "$landed" -a -d "$landed"; and cd $landed
            end

            bind -M insert \ez yz
            bind -M default \ez yz

            # zoxide counts accesses, not time: its hook adds a directory once per
            # change of the shell's PWD, so an hour of work in one directory counts
            # once while a directory merely passed through counts as much. Two
            # additions make the count follow the work instead:
            #
            #   - a shell starting in a directory counts it, because the PWD hook
            #     never fires for the directory a shell starts in;
            #   - every 20 commands run in the same directory count as one further
            #     access, so a long session weighs more than a visit.
            #
            # This block is the interactive shell's own init, so neither needs a
            # guard: a script's cwd is not a place you work.
            command zoxide add -- $PWD

            set -g __zoxide_activity 0
            function __zoxide_activity_reset --on-variable PWD
              set -g __zoxide_activity 0
            end
            function __zoxide_activity_count --on-event fish_postexec
              set -g __zoxide_activity (math $__zoxide_activity + 1)
              if test $__zoxide_activity -ge 20
                set -g __zoxide_activity 0
                command zoxide add -- $PWD
              end
            end

            set fzf_preview_dir_cmd eza --all --color=always
            # pistol, not bat: file previews share one association table across both
            # fzf surfaces — images would otherwise reach bat and render nothing.
            set fzf_preview_file_cmd pistol
            set fzf_diff_highlighter delta --paging=never --width=20

            bind -M insert \t _fzf_complete_lookahead
            bind -M default \t _fzf_complete_lookahead

            # fish's own pager keeps its key, so both menus stay reachable.
            bind -M insert ctrl-space complete-and-search
            bind -M default ctrl-space complete-and-search

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
    }

  ;
}
