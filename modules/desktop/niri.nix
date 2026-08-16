_: {
  flake.modules.homeManager.niri =
    {
      pkgs,
      ...
    }:
    {
      wayland.windowManager.niri = {
        enable = true;

        settings = {
          config-notification = {
            disable-failed = { };
          };

          # toKDL: repeated root nodes go through _children.
          _children = [
            {
              workspace = {
                _args = [ "home" ];
                open-on-output = "DP-1";
              };
            }
            {
              workspace = {
                _args = [ "dev" ];
                open-on-output = "DP-1";
              };
            }
            {
              workspace = {
                _args = [ "mb" ];
                open-on-output = "DP-1";
              };
            }

            {
              spawn-at-startup = [
                "uwsm"
                "finalize"
              ];
            }
            {
              spawn-at-startup = [
                "niri"
                "msg"
                "action"
                "focus-workspace"
                "main"
              ];
            }
            { spawn-at-startup = [ "${pkgs.nirius}/bin/niriusd" ]; }
          ];

          gestures.hot-corners.off = { };

          input = {
            keyboard = {
              xkb = {
                layout = "au,gb";
                options = "grp:ctrl_alt_space_toggle";
              };
              numlock = { };
            };
            touchpad = { };
            mouse = { };
            trackpoint = { };
          };

          blur = {
            passes = 3;
            offset = 3.0;
            noise = 0.01;
          };

          layout = {
            gaps = 5;
            background-color = "transparent";
            center-focused-column = "never";
            default-column-display = "tabbed";
            preset-column-widths._children = [
              { proportion = 0.33333; }
              { proportion = 0.5; }
              { proportion = 0.66667; }
            ];
            default-column-width = {
              proportion = 0.5;
            };
            tab-indicator = {
              hide-when-single-tab = { };
              position = "top";
              gaps-between-tabs = 25;
              width = 5.5;
              active-color = "MediumSpringGreen";
              inactive-color = "LightSteelBlue";
              corner-radius = 100;
              length._props = {
                total-proportion = 0.35;
              };
              gap = 6;
            };
            border = {
              off = { };
              width = 5;
              active-gradient._props = {
                from = "#f00f";
                to = "#0f05";
                angle = 45;
                "in" = "oklch longer hue";
              };
              inactive-color = "#d0d0d0";
              urgent-color = "#cc4444";
            };
            focus-ring = {
              width = 2;
              active-gradient._props = {
                from = "#f00f";
                to = "#0f05";
                angle = 45;
                "in" = "oklch longer hue";
              };
              inactive-color = "#505050";
            };
            shadow = {
              softness = 30;
              spread = 5;
              offset._props = {
                x = 0;
                y = 5;
              };
              color = "#0007";
            };
            struts = { };
          };

          overview.workspace-shadow.off = { };

          hotkey-overlay.skip-at-startup = { };

          prefer-no-csd = { };

          screenshot-path = "~/Pictures/Screenshots/Screenshot From %y-%m-%d %h-%m-%s.png";

          animations = {
            workspace-switch.spring._props = {
              "damping-ratio" = 0.80;
              stiffness = 523;
              epsilon = 0.0001;
            };
            window-open = {
              "duration-ms" = 150;
              curve = "ease-out-expo";
            };
            window-close = {
              "duration-ms" = 150;
              curve = "ease-out-quad";
            };
            horizontal-view-movement.spring._props = {
              "damping-ratio" = 0.85;
              stiffness = 423;
              epsilon = 0.0001;
            };
            window-movement.spring._props = {
              "damping-ratio" = 0.75;
              stiffness = 323;
              epsilon = 0.0001;
            };
            window-resize.spring._props = {
              "damping-ratio" = 0.85;
              stiffness = 423;
              epsilon = 0.0001;
            };
            config-notification-open-close.spring._props = {
              "damping-ratio" = 0.65;
              stiffness = 923;
              epsilon = 0.001;
            };
            screenshot-ui-open = {
              "duration-ms" = 200;
              curve = "ease-out-quad";
            };
            overview-open-close.spring._props = {
              "damping-ratio" = 0.85;
              stiffness = 800;
              epsilon = 0.0001;
            };
          };

          cursor = {
            "xcursor-theme" = "Bibata-Rainbow-Modern";
            # from dms/cursor.kdl
            "xcursor-size" = 26;
          };

          debug."honor-xdg-activation-with-invalid-serial" = { };
        };

        # Generic window rules and binds stay verbatim KDL. The Noctalia shell
        # integration and Monique's monitors.kdl include live in their own aspects.
        extraConfig = ''
          window-rule {
            background-effect {
              blur true
            }
            geometry-corner-radius 12
            clip-to-geometry true
            draw-border-with-background false
          }

          window-rule {
            match is-active=false
            opacity 0.70
          }

          window-rule {
            match is-active=true
            opacity 0.85
          }

          window-rule {
            match app-id="firefox"
            match app-id="brave"
            match app-id="okular"
            match app-id="libreoffice"
            opacity 0.90
          }

          window-rule {
            match app-id="firefox" is-active=false
            match app-id="brave" is-active=false
            match app-id="okular" is-active=false
            match app-id="libreoffice" is-active=false
            opacity 0.85
          }

          window-rule {
            match app-id=r#"^org\.gnome\."#
            draw-border-with-background false
            geometry-corner-radius 12
            clip-to-geometry true
          }

          window-rule {
            match app-id=r#"^gnome-control-center$"#
            match app-id=r#"^pavucontrol$"#
            match app-id=r#"^nm-connection-editor$"#
            default-column-width { proportion 0.5; }
            open-floating false
          }

          window-rule {
            match app-id=r#"^gnome-calculator$"#
            match app-id=r#"^galculator$"#
            match app-id=r#"^blueman-manager$"#
            match app-id=r#"^org\.gnome\.Nautilus$"#
            match app-id=r#"^steam$"#
            match app-id=r#"^xdg-desktop-portal$"#
            open-floating true
          }

          window-rule {
            match app-id=r#"^org\.wezfurlong\.wezterm$"#
            match app-id="Alacritty"
            match app-id="zen"
            match app-id="com.mitchellh.ghostty"
            match app-id="kitty"
            draw-border-with-background false
          }

          window-rule {
            match app-id=r#"$"# title="^Picture-in-Picture$"
            match app-id="zoom"
            match app-id="org.freedesktop.impl.portal"
            open-floating true
          }

          window-rule {
            match app-id="^brave-browser$"
            open-focused true
            open-on-workspace "mb"
          }

          window-rule {
            match app-id=r#"^brave-.*-Profile_1$"#
            open-on-workspace "home"
            default-column-width { proportion 0.33333; }
            open-focused false
            opacity 0.01
          }

          window-rule {
            match is-window-cast-target=true
            focus-ring {
              active-color "#f38ba8"
              inactive-color "#7d0d2d"
            }
            border {
              inactive-color "#7d0d2d"
            }
            shadow {
              color "#7d0d2d70"
            }
            tab-indicator {
              active-color "#f38ba8"
              inactive-color "#7d0d2d"
            }
          }

          window-rule {
            match app-id=r#"$"# title=r#"^Extension:"#
            match app-id=r#"^brave-.*-Default$"#
            match app-id="^OneDriveGUI$"
            open-floating true
          }

          binds {
            // === System & Overview ===
            Mod+D { spawn "niri" "msg" "action" "toggle-overview"; }
            Mod+Tab repeat=false { toggle-overview; }
            Mod+Shift+Slash { show-hotkey-overlay; }

            // === Application Launchers ===
            Mod+T hotkey-overlay-title="Open Terminal" { spawn "wezterm"; }
            Mod+Space hotkey-overlay-title="Application Launcher" {
              spawn "uwsm" "app" "--" "vicinae" "toggle";
            }
            Mod+E hotkey-overlay-title="Open File Manager" { spawn "dolphin"; }
            Mod+V hotkey-overlay-title="Clipboard Manager" { spawn "uwsm" "app" "--" "vicinae" "vicinae://launch/clipboard/history"; }

            Mod+Slash hotkey-overlay-title="File Search" {
              spawn "uwsm" "app" "--" "vicinae" "vicinae://launch/file/search";
            }

            Mod+U hotkey-overlay-title="Window Search" {
              spawn "uwsm" "app" "--" "vicinae" "vicinae://launch/@knoopx/store.vicinae.niri/windows";
            }

            // === Security ===
            Mod+Shift+E { quit; }

            // === Window Management ===
            Mod+Q repeat=false { close-window; }
            Mod+F { maximize-column; }
            Mod+Shift+F { fullscreen-window; }
            Mod+Alt+F { toggle-windowed-fullscreen; }
            Mod+Shift+Y hotkey-overlay-title="Send to Scratchpad" { spawn "nirius" "scratchpad-toggle"; }
            Mod+Shift+G hotkey-overlay-title="Show Scratchpad" { spawn "nirius" "scratchpad-show"; }
            Mod+Shift+T { toggle-window-floating; }
            Mod+Shift+V { switch-focus-between-floating-and-tiling; }
            Mod+W { toggle-column-tabbed-display; }

            // === Focus Navigation ===
            Mod+Left  { focus-column-left; }
            Mod+Down  { focus-window-down-or-top; }
            Mod+Up    { focus-window-up-or-bottom; }
            Mod+Right { focus-column-right; }
            Mod+H     { focus-column-left; }
            Mod+J     { focus-window-down; }
            Mod+K     { focus-window-up; }
            Mod+L     { focus-column-right; }

            // === Window Movement ===
            Mod+Shift+Left  { move-column-left; }
            Mod+Shift+Down  { move-window-down; }
            Mod+Shift+Up    { move-window-up; }
            Mod+Shift+Right { move-column-right; }
            Mod+Shift+H     { move-column-left; }
            Mod+Shift+J     { move-window-down; }
            Mod+Shift+K     { move-window-up; }
            Mod+Shift+L     { move-column-right; }

            // === Column Navigation ===
            Mod+Home { focus-column-first; }
            Mod+End  { focus-column-last; }
            Mod+Ctrl+Home { move-column-to-first; }
            Mod+Ctrl+End  { move-column-to-last; }

            // === Monitor Navigation ===
            Mod+Alt+Left  { focus-monitor-left; }
            Mod+Alt+Right { focus-monitor-right; }
            Mod+Alt+H     { focus-monitor-left; }
            Mod+Alt+J     { focus-monitor-down; }
            Mod+Alt+K     { focus-monitor-up; }
            Mod+Alt+L     { focus-monitor-right; }

            // === Move to Monitor ===
            Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
            Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
            Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
            Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
            Mod+Alt+Page_Up    { move-column-to-monitor-left; }
            Mod+Alt+Page_Down  { move-column-to-monitor-right; }
            Mod+Shift+Ctrl+H     { move-column-to-monitor-left; }
            Mod+Shift+Ctrl+J     { move-column-to-monitor-down; }
            Mod+Shift+Ctrl+K     { move-column-to-monitor-up; }
            Mod+Shift+Ctrl+L     { move-column-to-monitor-right; }

            // === Workspace Navigation ===
            Mod+Page_Down      { focus-workspace-down; }
            Mod+Page_Up        { focus-workspace-up; }
            Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
            Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
            Mod+Ctrl+K     { move-column-to-workspace-up; }
            Mod+Ctrl+J     { move-column-to-workspace-down; }

            Mod+Ctrl+Down { move-column-to-workspace-down; }
            Mod+Ctrl+Up   { move-column-to-workspace-up; }
            Mod+Ctrl+U         { move-column-to-workspace-down; }
            Mod+Ctrl+I         { move-column-to-workspace-up; }

            // === Move Workspaces ===
            Mod+Shift+Page_Down { move-workspace-down; }
            Mod+Shift+Page_Up   { move-workspace-up; }
            Mod+Shift+U         { move-workspace-down; }
            Mod+Shift+I         { move-workspace-up; }

            // === Mouse Wheel Navigation ===
            Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
            Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
            Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
            Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }

            Mod+WheelScrollRight      { focus-column-right; }
            Mod+WheelScrollLeft       { focus-column-left; }
            Mod+Ctrl+WheelScrollRight { move-column-right; }
            Mod+Ctrl+WheelScrollLeft  { move-column-left; }

            Mod+Shift+WheelScrollDown      { focus-column-right; }
            Mod+Shift+WheelScrollUp        { focus-column-left; }
            Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
            Mod+Ctrl+Shift+WheelScrollUp   { move-column-left; }

            // === Numbered Workspaces ===
            Mod+1 { focus-workspace 1; }
            Mod+2 { focus-workspace 2; }
            Mod+3 { focus-workspace 3; }
            Mod+4 { focus-workspace 4; }
            Mod+5 { focus-workspace 5; }
            Mod+6 { focus-workspace 6; }
            Mod+7 { focus-workspace 7; }
            Mod+8 { focus-workspace 8; }
            Mod+9 { focus-workspace 9; }

            // === Move to Numbered Workspaces ===
            Mod+Shift+1 { move-column-to-workspace 1; }
            Mod+Shift+2 { move-column-to-workspace 2; }
            Mod+Shift+3 { move-column-to-workspace 3; }
            Mod+Shift+4 { move-column-to-workspace 4; }
            Mod+Shift+5 { move-column-to-workspace 5; }
            Mod+Shift+6 { move-column-to-workspace 6; }
            Mod+Shift+7 { move-column-to-workspace 7; }
            Mod+Shift+8 { move-column-to-workspace 8; }
            Mod+Shift+9 { move-column-to-workspace 9; }

            // === Column Management ===
            Mod+BracketLeft  { consume-or-expel-window-left; }
            Mod+BracketRight { consume-or-expel-window-right; }
            Mod+Period { expel-window-from-column; }

            // === Sizing ===
            Mod+R { switch-preset-column-width; }
            Mod+Shift+R { switch-preset-window-height; }
            Mod+Ctrl+R { reset-window-height; }
            Mod+Ctrl+F { expand-column-to-available-width; }
            Mod+C { center-column; }
            Mod+Ctrl+C { center-visible-columns; }

            // === Manual Sizing ===
            Mod+Minus { set-column-width "-10%"; }
            Mod+Equal { set-column-width "+10%"; }
            Mod+Shift+Minus { set-window-height "-10%"; }
            Mod+Shift+Equal { set-window-height "+10%"; }

            // === Screenshots ===
            XF86Launch1 { screenshot; }
            Mod+Shift+S { screenshot; }
            Ctrl+XF86Launch1 { screenshot-screen; }
            Alt+XF86Launch1 { screenshot-window; }
            Print { screenshot; }
            Ctrl+Print { screenshot-screen; }
            Alt+Print { screenshot-window; }

            // === System Controls ===
            Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
            Mod+Shift+P { power-off-monitors; }
            Ctrl+Alt+Space { switch-layout "next"; }
          }
        '';
      };

      # force: pre-existing imperative file, backed up at niri.config.kdl.imperative-backup
      xdg.configFile."niri/config.kdl".force = true;

      # force: unmanaged regular file; legacy DMS shell desktop mask.
      xdg.configFile."autostart/DankMaterialShell.desktop".text = ''
        [Desktop Entry]
        Hidden=true
      '';

      home.packages = [
        pkgs.nirius
        pkgs.keypeek
      ];
    }

  ;
}
