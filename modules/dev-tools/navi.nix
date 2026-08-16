_: {
  flake.modules.homeManager.navi =
    { config, ... }:
    {
      programs.navi = {
        enable = true;
        enableZshIntegration = true;
        enableFishIntegration = true;

        settings = {
          style = {
            tag = {
              color = "blue";
              width_percentage = 26;
              min_width = 20;
            };
            comment = {
              color = "cyan";
              width_percentage = 42;
              min_width = 45;
            };
            snippet = {
              color = "green";
              width_percentage = 32;
              min_width = 35;
            };
          };
          finder = {
            command = "fzf";
            dropdown = {
              style = "minimal";
            };
          };
          cheat = {
            path = "${config.home.homeDirectory}/.local/share/navi/cheats";
          };
        };
      };

      home.file = {
        ".local/share/navi/cheats/systemd.cheat" = {
          text = ''
            % systemd, service, journalctl

            # Restart a user service and follow its logs
            systemctl --user restart <unit> && journalctl --user -u <unit> -f

            # Restart a system service and follow its logs
            sudo systemctl restart <unit> && journalctl -u <unit> -f

            # Follow logs for a user unit from current boot
            journalctl --user -u <unit> -b -n 50 --no-pager

            # List failed units
            systemctl list-units --failed --no-pager

            # Service status with full output
            systemctl status <unit> --no-pager -l

            # User service status
            systemctl --user status <unit> --no-pager -l

            % home-manager, nix, flake

            # Build home-manager generation
            home-manager build --flake .#saurabhj

            # Switch to home-manager generation
            home-manager switch --flake .#saurabhj

            # Update flake inputs and switch
            nix flake update && nh home switch

            # Rebuild and switch (host + home)
            sudo nixos-rebuild switch --flake . && nh home switch

            # Clean up old generations
            nh clean all --keep 3

            % nix, flake, development

            # Enter dev shell
            nix develop

            # Build and run from flake
            nix run .

            # Search nixpkgs for a package
            nix search nixpkgs <package>
          '';
          recursive = false;
        };
      };
    }

  ;
}
