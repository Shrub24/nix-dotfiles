{ inputs, ... }: {
  flake-file.inputs.vicinae = {
    url = "github:vicinaehq/vicinae/v0.29.2";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # The extensions and the capture CLI they front; behaviour and the launcher
  # surface that presents it version together here.
  flake-file.inputs.vicinae-extensions = {
    url = "github:Shrub24/vicinae-extensions";
    inputs.nixpkgs.follows = "nixpkgs";
    # The extensions build against the launcher that serves them, not a second
    # checkout of their own; following it also carries its nixpkgs.
    inputs.vicinae.follows = "vicinae";
  };

  flake.modules.homeManager.vicinae =
    { pkgs, ... }:
    {
      imports = [ inputs.vicinae.homeManagerModules.default ];

      programs.vicinae = {
        enable = true;
        # Entrypoints are fixed by each derivation's name; see the extensions flake.
        extensions = [
          inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}.screenshot-extension
          inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}.windows-extension
        ];
        systemd.enable = true;
        package = pkgs.vicinae;
        settings = {
          close_on_focus_loss = true;
          font = {
            rendering = "qt";
            normal = {
              family = "Maple Mono NF";
              size = 12;
            };
          };
          theme.dark.name = "noctalia";
          launcher_window = {
            opacity = 0.3;
            # liquid_glass is macOS-only; on Linux the layer blur rule in umbriel.nix is the glass.
            # material = "blur";
            rounding = 24;
            client_side_decorations = {
              enabled = true;
              border_width = 0;
            };
          };
          providers = {
            "@knoopx/store.vicinae.niri".entrypoints = {
              clear-dynamic-cast-target.enabled = false;
              pick-color.enabled = false;
            };
            "@sameoldlab/store.vicinae.fuzzy-files".enabled = false;
            applications.entrypoints = {
              io.github.tdesktop_x64_TDesktop.alias = "Telegram";
              jconsole-java-openjdk.enabled = false;
              jconsole-java21-openjdk.enabled = false;
              journalctl-desktop-notification.enabled = true;
              jshell-java-openjdk.enabled = false;
              jshell-java21-openjdk.enabled = false;
              micro.enabled = false;
              org.kde.kdeconnect.nonplasma.enabled = false;
              org.kde.kdeconnect.sms.enabled = false;
              vesktop.alias = "Discord";
            };
            clipboard.preferences.monitoring = true;
          };
        };
      };
    };
}
