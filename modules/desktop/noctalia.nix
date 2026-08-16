_: {
  flake.modules.homeManager.noctalia =
    {
      config,
      lib,
      inputs,
      pkgs,
      ...
    }:
    let
      noctaliaGreeterPackage = pkgs.noctalia-greeter;

      noctaliaGreeterSyncPkexec = pkgs.writeShellApplication {
        name = "noctalia-greeter-sync-pkexec";
        text = ''
          exec /usr/bin/pkexec /usr/local/libexec/noctalia-greeter-sync
        '';
      };
    in
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      # ponytail: niri's KDL parser rejects a second binds node in one file, so shell binds render into noctalia-binds.kdl included below.
      wayland.windowManager.niri.extraConfig =
        lib.mkIf (config ? wayland.windowManager.niri && config.wayland.windowManager.niri.enable)
          ''
            spawn-at-startup "noctalia"
            spawn-at-startup "noctalia-hide-action-bar"

            layer-rule {
              match namespace="^noctalia-backdrop"
              place-within-backdrop true
            }

            window-rule {
              match app-id="dev.noctalia.Noctalia"
              open-floating true
              default-column-width { fixed 1080; }
              default-window-height { fixed 920; }
            }

            include optional=true "noctalia-binds.kdl"
          '';

      xdg.configFile."niri/noctalia-binds.kdl" =
        lib.mkIf (config ? wayland.windowManager.niri && config.wayland.windowManager.niri.enable)
          {
            text = ''
              binds {
                // === Shell (Noctalia) ===
                Mod+A hotkey-overlay-title="Swap Action Bar" {
                  spawn "noctalia-bar-swap";
                }
                Mod+Comma hotkey-overlay-title="Settings" {
                  spawn "noctalia" "msg" "settings-toggle";
                }
                Mod+N hotkey-overlay-title="Control Center" {
                  spawn "noctalia" "msg" "panel-toggle" "control-center";
                }
                Mod+Y hotkey-overlay-title="Browse Wallpapers" {
                  spawn "noctalia" "msg" "wallpaper-next";
                }

                // === Security ===
                Ctrl+Alt+L hotkey-overlay-title="Lock Screen" {
                  spawn "noctalia" "msg" "session" "lock";
                }

                // === Audio Controls ===
                XF86AudioRaiseVolume allow-when-locked=true {
                  spawn "noctalia" "msg" "volume-up" "3";
                }
                XF86AudioLowerVolume allow-when-locked=true {
                  spawn "noctalia" "msg" "volume-down" "3";
                }
                XF86AudioMute allow-when-locked=true {
                  spawn "noctalia" "msg" "volume-mute";
                }
                XF86AudioMicMute allow-when-locked=true {
                  spawn "noctalia" "msg" "mic-mute";
                }

                // === Brightness Controls ===
                XF86MonBrightnessUp allow-when-locked=true {
                  spawn "noctalia" "msg" "brightness-up";
                }
                XF86MonBrightnessDown allow-when-locked=true {
                  spawn "noctalia" "msg" "brightness-down";
                }
              }
            '';
          };

      programs.noctalia = {
        enable = true;
        # nixpkgs' prebuilt package; the module default would build locally.
        package = pkgs.noctalia;
        settings = {
          theme = {
            mode = "dark";
            source = "wallpaper";
            wallpaper_scheme = "m3-tonal-spot";
            builtin = "Catppuccin";
            community_palette = "Oxocarbon";
          };

          wallpaper = {
            enabled = true;
            fill_mode = "crop";
            directory = "~/.local/share/wallpapers";
            automation = {
              enabled = true;
            };
            default.path = "${config.home.homeDirectory}/.local/share/wallpapers/wallpapersden.com_colorful-textured-abstract_3840x2160.jpg";
          };

          shell = {
            corner_radius_scale = 1.5;
            polkit_agent = true;
            greeter_sync.auto_sync = true;
            greeter_sync.privilege_command = "${noctaliaGreeterSyncPkexec}/bin/noctalia-greeter-sync-pkexec";
            external_ip_enabled = true;
            font_family = "Exo 2";
            password_style = "random";
            animation.speed = 1.95;
            panel = {
              transparency_mode = "glass";
              borders = true;
              shadow = true;
              control_center_placement = "attached";
              wallpaper_placement = "attached";
              session_placement = "floating";
              open_near_click_control_center = true;
            };
            session = {
              grid = true;
              grid_columns = 2;
            };
          };

          backdrop = {
            enabled = true;
            blur_intensity = 0.85;
            tint_intensity = 0.45;
          };

          bar.default = {
            background_opacity = 0.58;
            capsule_fill = "surface";
            capsule_foreground = "on_surface";
            capsule_opacity = 0.06;
            capsule_padding = 17.0;
            color = "secondary";
            contact_shadow = true;
            font_weight = 600;
            hover_highlight = false;
            icon_color = "tertiary";
            margin_edge = 4;
            margin_ends = 26;
            padding = 16;
            radius = 18;
            shadow = true;
            thickness = 38;
            widget_spacing = 8;
            dead_zone.actions = {
              scroll_up = "exec niri msg action focus-workspace-up";
              scroll_down = "exec niri msg action focus-workspace-down";
            };
            start = [
              "group:g3"
              "group:g6"
            ];
            center = [ "group:g1" ];
            end = [
              "group:g4"
              "group:g2"
            ];
            capsule_group = [
              {
                enabled = true;
                fill = "surface";
                foreground = "on_surface";
                id = "g1";
                members = [
                  "clock"
                  "bar"
                  "audio_visualizer"
                  "media"
                ];
                opacity = 0.06;
                padding = 0.0;
              }
              {
                enabled = true;
                fill = "surface";
                foreground = "on_surface";
                id = "g2";
                members = [
                  "bluetooth"
                  "network"
                  "volume"
                  "battery"
                  "brightness"
                  "control-center"
                  "session"
                ];
                opacity = 0.06;
                padding = 13.0;
              }
              {
                enabled = true;
                fill = "surface";
                foreground = "on_surface";
                id = "g3";
                members = [
                  "notifications"
                  "ram"
                  "sysmon"
                ];
                opacity = 0.06;
                padding = 7.0;
              }
              {
                enabled = true;
                fill = "surface";
                foreground = "on_surface";
                id = "g4";
                members = [
                  "tray"
                  "icefish/phone-connect:bar"
                  "clipboard"
                ];
                opacity = 0.06;
                padding = 14.0;
              }
              {
                enabled = true;
                fill = "surface";
                foreground = "on_surface";
                id = "g6";
                members = [
                  "active-workspace"
                  "active_window"
                ];
                opacity = 0.06;
                padding = 9.0;
              }
            ];
          };

          bar.action = {
            position = "top";
            layer = "overlay";
            reserve_space = false;
            background_opacity = 0.58;
            capsule_fill = "surface";
            capsule_foreground = "on_surface";
            capsule_opacity = 0.06;
            capsule_padding = 17.0;
            color = "secondary";
            contact_shadow = true;
            font_weight = 600;
            hover_highlight = false;
            icon_color = "tertiary";
            margin_edge = 4;
            margin_ends = 26;
            padding = 16;
            radius = 18;
            shadow = true;
            thickness = 38;
            widget_spacing = 8;
            start = [
              "kenn/keybind-cheatsheet:keybinds"
              "launcher"
              "wallpaper"
            ];
            center = [ "group:g1" ];
            end = [ "salemsayed/codexbar-meter:bar" ];
            capsule_group = [
              {
                enabled = true;
                fill = "surface";
                foreground = "on_surface";
                id = "g1";
                members = [
                  "screenshot"
                  "elijaharch/wl-screen-mirror:mirror"
                  "noctalia/screen_recorder:recorder"
                  "alexander/screen-toolkit:widget"
                ];
                opacity = 0.06;
                padding = 17.0;
              }
            ];
          };

          battery.warning_threshold = 15;

          brightness = {
            enable_ddcutil = true;
            minimum_brightness = 0.1;
            sync_all_monitors = true;
          };

          calendar.enabled = true;

          control_center.shortcuts = [
            { type = "wifi"; }
            { type = "bluetooth"; }
            { type = "caffeine"; }
            { type = "notification"; }
            { type = "power_profile"; }
            { type = "audio"; }
          ];

          desktop_widgets = {
            schema_version = 2;
            widget_order = [
              "desktop-widget-0000000000000001"
              "desktop-widget-0000000000000003"
              "desktop-widget-0000000000000004"
              "desktop-widget-0000000000000005"
            ];
            grid = {
              cell_size = 16;
              major_interval = 4;
              visible = true;
            };
            widget = {
              "desktop-widget-0000000000000001" = {
                box_height = 512.0;
                box_width = 560.0;
                cx = 381.5;
                cy = 837.5;
                output = "eDP-1";
                rotation = 0.0;
                type = "fancy_audio_visualizer";
                settings = {
                  background = false;
                  bar_width = 0.7;
                  bloom_intensity = 0.5;
                  inner_diameter = 0.4;
                  primary_color = "secondary";
                  ring_opacity = 0.4;
                  secondary_color = "on_secondary";
                  visualization_mode = "bars_rings";
                };
              };
              "desktop-widget-0000000000000003" = {
                box_height = 320.0;
                box_width = 560.0;
                cx = 853.5;
                cy = 533.5;
                flip_x = true;
                output = "eDP-1";
                rotation = 0.0;
                type = "audio_visualizer";
                settings = {
                  background = false;
                  bands = 64;
                  centered = true;
                  color_1 = "on_secondary";
                  color_2 = "secondary";
                  mirrored = true;
                  show_when_idle = true;
                };
              };
              "desktop-widget-0000000000000004" = {
                box_height = 304.0;
                box_width = 192.0;
                cx = 389.5;
                cy = 381.5;
                output = "eDP-1";
                rotation = 0.0;
                type = "media_player";
                settings = {
                  background = false;
                  color = "error";
                  hide_when_no_media = true;
                  layout = "vertical";
                };
              };
              "desktop-widget-0000000000000005" = {
                box_height = 0.0;
                box_width = 0.0;
                cx = 853.5;
                cy = 293.5;
                output = "eDP-1";
                rotation = 0.0;
                type = "clock";
                settings = {
                  background = false;
                  color = "secondary";
                };
              };
            };
          };

          location.auto_locate = true;

          lockscreen_widgets = {
            enabled = false;
            schema_version = 2;
            widget_order = [
              "lockscreen-login-box@DP-1"
              "lockscreen-login-box@eDP-1"
            ];
            grid = {
              cell_size = 16;
              major_interval = 4;
              visible = true;
            };
            widget = {
              "lockscreen-login-box@DP-1" = {
                box_height = 196.0;
                box_width = 810.0;
                cx = 1720.0;
                cy = 1258.0;
                output = "DP-1";
                rotation = 0.0;
                type = "login_box";
                settings = {
                  background_color = "surface_variant";
                  background_opacity = 0.88;
                  background_radius = 12.0;
                  center_password_text = false;
                  input_opacity = 1.0;
                  input_radius = 6.0;
                  layout = "regular";
                  show_caps_lock = true;
                  show_keyboard_layout = true;
                  show_login_button = true;
                  show_media = true;
                  show_session_buttons = true;
                  show_unlock_hint = true;
                  show_weather = true;
                };
              };
              "lockscreen-login-box@eDP-1" = {
                box_height = 196.0;
                box_width = 810.0;
                cx = 854.0;
                cy = 885.0;
                output = "eDP-1";
                rotation = 0.0;
                type = "login_box";
                settings = {
                  background_color = "surface_variant";
                  background_opacity = 0.88;
                  background_radius = 12.0;
                  center_password_text = false;
                  input_opacity = 1.0;
                  input_radius = 6.0;
                  layout = "regular";
                  show_caps_lock = true;
                  show_keyboard_layout = true;
                  show_login_button = true;
                  show_media = true;
                  show_session_buttons = true;
                  show_unlock_hint = true;
                  show_weather = true;
                };
              };
            };
          };

          widget = {
            network = {
              show_label = false;
            };

            media = {
              hide_artist = true;
            };

            audio_visualizer = {
              anchor = true;
              bands = 20;
              color_2 = "tertiary";
              mirrored = false;
              show_when_idle = true;
              width = 96;
            };

            active-workspace = {
              type = "salemsayed/niri-active-workspace:active-workspace";
            };

            bar = {
              type = "noctalia/world_clock:bar";
            };

            widget = {
              type = "alexander/screen-toolkit:widget";
            };

            "salemsayed/codexbar-meter:bar" = {
              enabled = false;
              scale = 1.3;
            };
          };

          plugin_settings = {
            "icefish/phone-connect".device_alias = "S23 Ultra";
            "kenn/keybind-cheatsheet" = {
              columns = 4;
              compositor = "niri";
              show_actions = false;
              show_undescribed = false;
            };
            "salemsayed/codexbar-meter".barProviderLimit = 2;
          };

          plugins = {
            enabled = [
              "noctalia/screen_recorder"
              "salemsayed/codexbar-meter"
              "lux/ideapad-conservation-mode"
              "kenn/keybind-cheatsheet"
              "icefish/phone-connect"
              "elijaharch/wl-screen-mirror"
              "noctalia/world_clock"
              "noctalia/notes"
              "alexander/screen-toolkit"
              "salemsayed/niri-active-workspace"
              "dotnetrob/cat"
            ];
          };

          notification = {
            position = "top_right";
            background_opacity = 0.78;
          };
          osd.background_opacity = 0.78;
        };
      };

      home.packages = [
        pkgs.codexbar
        noctaliaGreeterPackage
        (pkgs.writeShellApplication {
          name = "noctalia-bar-swap";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.noctalia
          ];
          text = ''
            state_file="''${XDG_RUNTIME_DIR:-/tmp}/noctalia-action-bar"
            if [ -f "$state_file" ]; then
              rm -f "$state_file"
              noctalia msg bar-hide action
              noctalia msg bar-show default
            else
              touch "$state_file"
              noctalia msg bar-hide default
              noctalia msg bar-show action
            fi
          '';
        })
        (pkgs.writeShellApplication {
          name = "noctalia-hide-action-bar";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.noctalia
          ];
          text = ''
            rm -f "''${XDG_RUNTIME_DIR:-/tmp}/noctalia-action-bar"
            for _ in {1..50}; do
              if noctalia msg bar-hide action >/dev/null 2>&1; then
                noctalia msg bar-show default >/dev/null
                sleep 1
                noctalia msg bar-hide action >/dev/null
                exit 0
              fi
              sleep 0.2
            done
            exit 1
          '';
        })
      ];
    }

  ;
}
