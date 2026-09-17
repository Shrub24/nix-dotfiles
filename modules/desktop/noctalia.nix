{
  inputs,
  config,
  ...
}:
let
  # Typed primary-user topology; the greeter-sync helper derives its UID from it.
  primaryUser = config.topology.hosts.arch.primaryUser;
in
{
  flake.modules.homeManager.noctalia =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      noctaliaGreeterPackage = pkgs.noctalia-greeter;

      # Template inputs: upstream's builtins ship inside the package, the
      # community ones come from the pinned flake input, and the rest are our own
      # templates in modules/desktop/noctalia-templates.
      builtinTemplates = "${pkgs.noctalia}/share/noctalia/assets/templates";
      localTemplates = ./noctalia-templates;
      templateHooks = pkgs.noctalia-template-hooks;

      # Built-in rows: [dir file] read from the noctalia package assets.
      # `script` is the template's own apply.sh in that directory; `action` is a
      # Noctalia-native post action. A row with neither needs no hook because
      # Nix points the consuming app at the rendered file.
      builtinRows = [
        {
          id = "btop";
          dir = "btop";
          file = "btop.theme";
          out = "$XDG_CONFIG_HOME/btop/themes/noctalia.theme";
          script = { };
        }
        {
          id = "cava";
          dir = "cava";
          file = "cava.ini";
          out = "$XDG_CONFIG_HOME/cava/themes/noctalia";
          script = { };
        }
        {
          id = "kcolorscheme";
          dir = "kde";
          file = "kcolorscheme.colors";
          out = "$XDG_DATA_HOME/color-schemes/noctalia.colors";
          action = "kde-color-scheme";
        }
        {
          id = "starship";
          dir = "starship";
          file = "starship.toml";
          out = "$XDG_CACHE_HOME/noctalia/starship-palette.toml";
          script = { };
        }
        {
          # wezterm.lua sets color_scheme = "Noctalia" and reload-watches this
          # file, so upstream's config-editing hook is not needed.
          id = "wezterm";
          dir = "wezterm";
          file = "wezterm.toml";
          out = "$XDG_CONFIG_HOME/wezterm/colors/Noctalia.toml";
        }
        {
          # ghostty.nix sets theme = "noctalia"; upstream's reload.sh (config
          # edit stripped) only pokes the running instance to re-read the theme.
          id = "ghostty";
          dir = "ghostty";
          file = "ghostty";
          out = "$XDG_CONFIG_HOME/ghostty/themes/noctalia";
          cmd = "bash ${builtinTemplates}/ghostty/reload.sh";
        }
        {
          # kitty.nix includes themes/noctalia.conf; upstream's apply.sh is
          # config editing, so just poke running instances (SIGUSR1 = reload).
          id = "kitty";
          dir = "kitty";
          file = "kitty.conf";
          out = "$XDG_CONFIG_HOME/kitty/themes/noctalia.conf";
          cmd = "pkill -USR1 -x kitty || true";
        }
        {
          # foot.ini declares the include; upstream's apply.sh is entirely
          # config editing, so no hook — foot re-reads on next launch.
          id = "foot";
          dir = "foot";
          file = "foot";
          out = "$XDG_CONFIG_HOME/foot/themes/noctalia";
        }
      ];

      # Community rows: [dir file] read from inputs.community-templates.
      communityRows = [
        {
          id = "bat";
          dir = "bat";
          file = "bat.tmTheme";
          out = "$XDG_CONFIG_HOME/bat/themes/noctalia.tmTheme";
          cmd = "${templateHooks.bat}/bin/noctalia-template-bat";
        }
        {
          # Upstream's hook writes the theme PNGs and syncs Brave's Preferences;
          # it only reads the rendered manifest.
          id = "brave-origin";
          dir = "brave-origin";
          file = "manifest.json";
          out = "$XDG_CACHE_HOME/noctalia/brave-origin-theme/manifest.json";
          script.args = "{{ mode }}";
        }
        {
          id = "fzf";
          dir = "fzf";
          file = "fzf.sh";
          out = "$XDG_CONFIG_HOME/fzf/themes/noctalia.sh";
        }
        {
          id = "fzf-fish";
          dir = "fzf";
          file = "fzf.fish";
          out = "$XDG_CONFIG_HOME/fzf/themes/noctalia.fish";
        }
        {
          id = "feishin";
          dir = "feishin";
          file = "custom.css";
          out = "$XDG_CONFIG_HOME/feishin/custom.css";
        }
        {
          id = "glow";
          dir = "glow";
          file = "glow.json";
          out = "$XDG_CONFIG_HOME/glow/noctalia.json";
        }
        {
          id = "lazygit";
          dir = "lazygit";
          file = "lazygit.yml";
          out = "$XDG_CONFIG_HOME/lazygit/themes/noctalia.yml";
          script = { };
        }
        {
          # Upstream builds the .oxt inside its own directory, so it runs from a
          # staged copy via the generic `stage` helper.
          id = "libreoffice";
          dir = "libreoffice";
          file = "Theme_Colors.xcu";
          out = "$XDG_STATE_HOME/noctalia/libreoffice-theme-staging/Theme_Colors.xcu";
          stage = true;
        }
        {
          id = "micro";
          dir = "micro";
          file = "noctalia.micro";
          out = "$XDG_CONFIG_HOME/micro/colorschemes/noctalia.micro";
          script = { };
        }
        {
          id = "obs";
          dir = "obs";
          file = "matugen.obt";
          out = "$XDG_CONFIG_HOME/obs-studio/themes/matugen.obt";
        }
        {
          id = "opencode";
          dir = "opencode";
          file = "opencode.json";
          out = "$XDG_CONFIG_HOME/opencode/themes/matugen.json";
        }
        {
          id = "pywalfox-beta4";
          dir = "pywalfox-beta4";
          file = "pywalfox.json";
          out = "$XDG_CACHE_HOME/wal/colors.json";
          action = "firefox-theme";
        }
        {
          # tmux.conf sources this file from the Nix-rendered config.
          id = "tmux";
          dir = "tmux";
          file = "tmux.conf";
          out = "$XDG_CONFIG_HOME/tmux/themes/noctalia.conf";
        }
        {
          # Vicinae's theme is named in modules/desktop/vicinae.nix; no hook.
          id = "vicinae";
          dir = "vicinae";
          file = "vicinae.toml";
          out = "$XDG_DATA_HOME/vicinae/themes/noctalia.toml";
        }
        {
          id = "yazi";
          dir = "yazi";
          file = "yazi.toml";
          out = "$XDG_CONFIG_HOME/yazi/flavors/noctalia.yazi/flavor.toml";
          script = { };
        }
        {
          id = "zathura";
          dir = "zathura";
          file = "zathurarc";
          out = "$XDG_CONFIG_HOME/zathura/noctaliarc";
          script = { };
        }
        {
          # Only the Midnight flavour of upstream's Discord CSS is rendered; the
          # theme is selected inside Vesktop.
          id = "vesktop";
          dir = "discord";
          file = "discord-midnight.css";
          out = "$XDG_CONFIG_HOME/vesktop/themes/noctalia.theme.css";
        }
      ];

      # The pinned input is 7.7 MB of every community template; keep only the
      # directories the rows above read from. lib.fileset rejects a flake input
      # (a store path held as a string), so the wanted directories are copied out.
      communityTemplates = pkgs.runCommand "noctalia-community-templates" { } ''
        mkdir -p $out
        ${lib.concatMapStringsSep "\n" (dir: "cp -r ${inputs.community-templates}/${dir} $out/") (
          lib.unique (map (row: row.dir) communityRows)
        )}
      '';

      # Rows become template entries. `root` is the input the row's paths are
      # relative to, so the same builder serves both tables.
      templateEntries =
        root: rows:
        builtins.listToAttrs (
          map (
            row:
            let
              scriptHook =
                lib.optionalString (row ? script)
                  "bash ${root}/${row.dir}/apply.sh${lib.optionalString (row.script ? args) " ${row.script.args}"}";
              hook =
                row.cmd or (
                  if row ? stage then
                    "${templateHooks.stage}/bin/noctalia-template-stage ${root}/${row.dir}"
                  else if scriptHook != "" then
                    scriptHook
                  else
                    null
                );
            in
            {
              name = row.id;
              value = {
                input_path = "${root}/${row.dir}/${row.file}";
                output_path = row.out;
              }
              // lib.optionalAttrs (row ? action) { post_action = row.action; }
              // lib.optionalAttrs (hook != null) { post_hook = hook; };
            }
          ) rows
        );

      user =
        templateEntries builtinTemplates builtinRows
        // templateEntries communityTemplates communityRows
        // {
          # Our own templates. fastfetch's config *is* the template: Noctalia
          # renders the whole file, palette placeholders included, so no hook and
          # no merge step is involved.
          fastfetch = {
            input_path = "${localTemplates}/fastfetch.jsonc";
            output_path = "$XDG_CONFIG_HOME/fastfetch/config.jsonc";
          };
          # Upstream's mapping renders secondary text (todos, timestamps,
          # thinking) at on_surface_variant and "very dim" text at
          # outline_variant, which is ~2:1 on the dark background. The local copy
          # shifts both tiers up; see the vars block in the file.
          pi-agent = {
            input_path = "${localTemplates}/pi-agent.json";
            output_path = "${config.home.homeDirectory}/.pi/agent/themes/noctalia.json";
          };
          # Fork of the community neovim template so base0C/0D/0E can use the
          # bright tonal tier; upstream's `*_fixed_dim` roles are the same value
          # as the base roles. Local rather than upstream so apply.sh stays out of
          # the config.
          neovim = {
            input_path = "${localTemplates}/neovim.lua";
            output_path = "$XDG_CONFIG_HOME/nvim/lua/matugen.lua";
            post_hook = "${pkgs.procps}/bin/pkill -SIGUSR1 -x nvim || true";
          };
        };

      # Specialized at the feature use site: uid from typed topology.
      noctaliaGreeterSync = pkgs.callPackage ../../pkgs/noctalia-greeter-sync {
        inherit (primaryUser) uid;
      };

      # Packaged seed for the mutable wallpaper. Copied into the user home only
      # when absent (tmpfiles `C`, not `C+`), so a runtime-edited wallpaper survives
      # switches. The packaged source is PNG where the destination ends in `.jpg`;
      # Qt inspects content, so no conversion dependency is added.
      wallpaperSeed = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;

      noctaliaGreeterSyncPkexec = pkgs.writeShellApplication {
        name = "noctalia-greeter-sync-pkexec";
        # NixOS resolves the security.wrappers pkexec; generic-Linux hosts use
        # the distro pkexec.
        text = ''
          exec ${
            if config.targets.genericLinux.enable then "/usr/bin/pkexec" else "/run/wrappers/bin/pkexec"
          } ${noctaliaGreeterSync}/bin/noctalia-greeter-sync
        '';
      };
    in
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      # Bootstrap the mutable wallpaper directory + seed on first activation.
      # xdg.dataFile would store-link the destination and break runtime changes;
      # `d`+`C` create mutable paths under user ownership and copy the seed only
      # when absent. `C` (not `C+`) preserves a pre-existing wallpaper.
      systemd.user.tmpfiles.rules = [
        "d %h/.local/share/wallpapers 0755 - - -"
        "C %h/.local/share/wallpapers/wallpapersden.com_colorful-textured-abstract_3840x2160.jpg 0644 - - - ${wallpaperSeed}"
      ];

      # ponytail: niri's KDL parser rejects a second binds node in one file, so shell binds render into noctalia-binds.kdl included below.
      xdg.configFile."niri/noctalia.kdl" =
        lib.mkIf (config ? wayland.windowManager.niri && config.wayland.windowManager.niri.enable)
          {
            text = ''
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
          };

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

            # Template definitions. Upstream's builtin and community catalogues
            # are switched off: `templates` below is the whole set, so which
            # templates exist, where they render, and what runs afterwards is
            # ours, and nothing is downloaded at apply time.
            #
            # The rows are the single source of truth — the same table drives
            # both the entries and the input filter, so a row cannot supply one
            # without the other. Inputs are store paths: the noctalia package for
            # builtins, the pinned community-templates input for the rest.
            #
            # A row carries a hook only when the consuming app cannot be pointed
            # at the rendered file from Nix; see the per-row comments below.
            templates = {
              enable_builtin_templates = false;
              enable_community_templates = false;

              inherit user;
            };
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
            reserve_space = true;
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
              enabled = true;
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
            # screen_recorder is deliberately absent: screen-toolkit covers the
            # same ground and the recorder widget is not on either bar.
            enabled = [
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
        # Template hook dependencies, resolved through the noctalia daemon's PATH
        # (~/.nix-profile/bin precedes /usr/bin): `zip` for the libreoffice hook,
        # python3 with Pillow for the brave-origin hook's PNG generation.
        pkgs.zip
        (pkgs.python3.withPackages (p: [ p.pillow ]))
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
