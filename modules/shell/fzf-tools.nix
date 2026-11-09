_: {
  # Picker commands built on fzf's defaults: they inherit the palette from
  # programs.fzf.colors and the layout from programs.fzf.defaultOptions, so each
  # script only declares what is specific to its own list.
  flake.modules.homeManager.fzf-tools =
    { pkgs, ... }:
    let
      # Content search. fzf stops filtering (--disabled) and re-runs ripgrep on every
      # keystroke instead, because the query has to select the matches, not filter a
      # stale set of them.
      rgf = pkgs.writeShellApplication {
        name = "rgf";
        runtimeInputs = with pkgs; [
          bat
          fzf
          ripgrep
        ];
        # The bind commands are single-quoted on purpose: fzf expands them itself.
        excludeShellChecks = [ "SC2016" ];
        text = ''
          rg_args=(--column --line-number --no-heading --color=always --smart-case --max-columns=512)
          # Resolved here, not inside the bind: fzf runs its commands through $SHELL,
          # which is fish on this machine, where a POSIX ${"VAR:-default"} is a syntax
          # error.
          editor=''${EDITOR:-nvim}

          exec fzf --ansi --disabled --query "''${*:-}" \
            --delimiter=: \
            --bind "start:reload:rg ''${rg_args[*]} {q} || true" \
            --bind "change:reload:sleep 0.1; rg ''${rg_args[*]} {q} || true" \
            --preview 'bat --style=numbers --color=always --highlight-line {2} -- {1}' \
            --preview-window 'right,60%,+{2}-/2' \
            --preview-label 'match' \
            --header 'enter: open at the matching line' \
            --bind "enter:become($editor +{2} {1})"
        '';
      };

      # Unit picker: the list is short enough to scan, and the preview is the status
      # that would otherwise need a second command. Journal browsing is lazyjournal's
      # job, so nothing here duplicates it.
      unit = pkgs.writeShellApplication {
        name = "unit";
        runtimeInputs = with pkgs; [
          coreutils
          fzf
          gawk
          systemd
        ];
        excludeShellChecks = [ "SC2016" ];
        text = ''
          units=$(systemctl list-units --all --plain --no-legend --no-pager | awk '{ print $1 }' | sort -u)

          exec fzf --ansi --no-sort --prompt 'unit> ' \
            --header 'enter: status   ctrl-j: journal' \
            --preview 'systemctl status --no-pager -n 12 {} 2>&1' \
            --preview-window 'right,60%,wrap' \
            --preview-label 'status' \
            --bind 'enter:become(systemctl status {})' \
            --bind 'ctrl-j:become(journalctl -u {} -f -n 200)' <<<"$units"
        '';
      };
    in
    {
      home.packages = [
        rgf
        unit
      ];
    };
}
