{ inputs, ... }: {
  flake-file.inputs.vicinae.url = "github:vicinaehq/vicinae";

  flake.modules.homeManager.vicinae =
    { ... }:
    {
      imports = [ inputs.vicinae.homeManagerModules.default ];

      programs.vicinae = {
        enable = true;
        systemd.enable = true;
        settings = {
          close_on_focus_loss = true;
          font = {
            rendering = "qt";
            normal = {
              family = "Maple Mono";
              size = 10.5;
            };
          };
          # Noctalia renders the theme under this name (see the vicinae entry in
          # modules/desktop/noctalia.nix), so selection needs no hook.
          theme.dark.name = "noctalia";
          launcher_window.opacity = 0.85;
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
