{
  # This aspect must be imported after `fish`: the integration installs a `\r`
  # binding for the transient prompt, which `fish_vi_key_bindings` would clobber.
  flake.modules.homeManager.starship =
    { pkgs, lib, ... }:
    let
      jjStarship = lib.getExe pkgs.jj-starship;
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

          format = "$username$hostname$directory\${custom.jj}$line_break$character";
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

          # jj-starship covers both jj and plain git repos, so starship's own
          # git modules stay off.
          git_branch.disabled = true;
          git_status.disabled = true;

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

          # jj-starship reads repo state without snapshotting the working copy.
          custom.jj = {
            description = "jj-starship: VCS state for jj and git repos";
            when = "${jjStarship} detect";
            shell = [ jjStarship ];
            format = "$output ";
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
