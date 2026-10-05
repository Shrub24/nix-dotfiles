{
  # This aspect must be imported after `fish`: the integration installs a `\r`
  # binding for the transient prompt, which `fish_vi_key_bindings` would clobber.
  flake.modules.homeManager.starship =
    _:
    let
      # Private-use glyphs are invisible in source, so glyphs are built from codepoints.
      glyph = cp: builtins.fromJSON "\"\\u${cp}\"";
      glyphs = {
        clock = glyph "F017"; # nf-fa-clock_o
        hourglass = glyph "F252"; # nf-fa-hourglass_half
        failure = glyph "F00D"; # nf-fa-times
        lock = glyph "F023"; # nf-fa-lock
        nix = glyph "F313"; # nf-linux-nixos
        direnv = glyph "25BC"; # ▼
      };
    in
    {
      programs.starship = {
        enable = true;
        enableTransience = true;

        settings = {
          add_newline = false;
          scan_timeout = 10;
          command_timeout = 200;

          format = "$username$hostname$directory$git_branch\${custom.vcs}$line_break$character";
          right_format = "$nix_shell$direnv$cmd_duration$status$jobs$time";

          username = {
            show_always = false;
            style_user = "bold yellow";
            format = "[$user]($style)@";
          };

          hostname = {
            ssh_only = true;
            style = "bold yellow";
            format = "[$hostname]($style) ";
          };

          # ANSI names, not hex: the noctalia palette resolves them, but it collapses
          # most roles — only the distinguishable ones are used below.
          directory = {
            # truncate_to_repo would read as a bare "nix" at the repo root.
            truncate_to_repo = false;
            truncation_length = 3;
            truncation_symbol = "…/";
            style = "bold white";
            read_only = "${glyphs.lock} ";
          };

          git_branch = {
            format = "[$symbol$branch]($style) ";
            # A jj repo is always on a detached HEAD, so this would render a bare "HEAD"
            # where the change id is the real identity; a plain git checkout still shows
            # its branch. The jj state line lives in custom.vcs below.
            ignore_branches = [ "HEAD" ];
          };

          # status, time and direnv are disabled by default; their modules only
          # render once that is off.
          status = {
            disabled = false;
            symbol = "${glyphs.failure} ";
            style = "bold red";
            # The bare number says nothing useful; common_meaning/signal_name do.
            format = "[$symbol$common_meaning$signal_name$maybe_int]($style) ";
          };

          cmd_duration = {
            min_time = 3000;
            style = "bright-black";
            format = "[${glyphs.hourglass} $duration]($style) ";
          };

          time = {
            disabled = false;
            time_format = "%T";
            style = "bright-black";
            format = "[${glyphs.clock} $time]($style) ";
          };

          jobs = {
            style = "bright-black";
          };

          nix_shell = {
            symbol = "${glyphs.nix} ";
            style = "bold blue";
            format = "[$symbol$state]($style) ";
          };

          direnv = {
            disabled = false;
            symbol = "${glyphs.direnv} ";
            style = "bold yellow";
            format = "[$symbol$loaded]($style) ";
          };

          character = {
            success_symbol = "[❯](bold green)";
            error_symbol = "[❯](bold red)";
            vimcmd_symbol = "[❮](bold yellow)";
            vimcmd_visual_symbol = "[❮](bold yellow)";
          };

          # The VCS state line. starship's git_status is deliberately not used: in a
          # colocated jj repo it reports the working copy a second time. --ignore-working-copy
          # keeps the prompt read-only — rendering never takes a snapshot.
          custom.vcs = {
            description = "jj change id, working-copy diff and conflict state";
            # shell=["sh"]: fish would reject the POSIX script below; only the binary
            # belongs here — an explicit -c makes starship expect an argument it never passes.
            shell = [ "sh" ];
            when = "jj root --quiet >/dev/null 2>&1 || git rev-parse --git-dir >/dev/null 2>&1";
            command = ''
              if jj root --quiet >/dev/null 2>&1; then
                printf '@%s' "$(
                  jj log --no-graph --ignore-working-copy --color never -r @ \
                    -T 'separate(" ", bookmarks, change_id.shortest(8)) ++ if(conflict, " ⚠", "") ++ if(self.diff().files().len() > 0, " " ++ self.diff().files().len() ++ "f", "")' \
                    2>/dev/null
                )"
              else
                n=$(git status --porcelain 2>/dev/null | wc -l)
                [ "$n" -gt 0 ] && printf '%sf' "$n"
              fi
            '';
            style = "bold magenta";
            format = "([$output]($style) )";
          };

          # Default modules that cannot apply here, or that cost a filesystem scan per prompt.
          package.disabled = true;
          aws.disabled = true;
          gcloud.disabled = true;
          docker_context.disabled = true;
          kubernetes.disabled = true;
        };
      };
    };
}
