{
  inputs,
  ...
}:
{
  flake-file.inputs = {
    noctalia = {
      url = "github:noctalia-dev/noctalia/v5.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia fetches community templates from api.noctalia.dev at runtime;
    # pinning the source repo keeps the template inputs declarative.
    community-templates = {
      url = "github:noctalia-dev/community-templates";
      flake = false;
    };

    # Sweet's Sass sources. The palette is injected at render time, so the theme
    # is rebuilt on every colour change rather than shipped pre-coloured.
    sweet = {
      url = "github:EliverLara/Sweet";
      flake = false;
    };
  };

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
      # Noctalia runs a template's apply.sh after rendering it. Both hooks are
      # replacements for upstream's, which assume a writable home and an
      # unmanaged bat config.
      templateHooks = {
        # Upstream's bat hook also rewrites ~/.config/bat/config, which is
        # Nix-rendered here (the theme comes from BAT_THEME), so only the cache
        # rebuild is left.
        bat = pkgs.writeShellApplication {
          name = "noctalia-template-bat";
          runtimeInputs = [ pkgs.bat ];
          text = "bat cache --build";
        };

        # apply.sh runs from a writable copy: upstream's libreoffice hook
        # assembles its .oxt inside the template dir, read-only in the store.
        stage = pkgs.writeShellApplication {
          name = "noctalia-template-stage";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.zip
            pkgs.python3
          ];
          text = ''
            if [ "$#" -ne 1 ]; then
              echo "usage: noctalia-template-stage <template-dir>" >&2
              exit 2
            fi
            source_dir="$1"
            build="''${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/template-stage/$(basename "$source_dir")"
            rm -rf "$build"
            mkdir -p "$(dirname "$build")"
            cp -r "$source_dir" "$build"
            chmod -R u+w "$build"
            exec bash "$build/apply.sh"
          '';
        };

        # Sweet's own colours are literal in its compiled CSS, so a palette can
        # only reach it by rebuilding: substitute the palette into the Sass
        # sources, then compile both toolkits.
        sweet = pkgs.writeShellApplication {
          name = "noctalia-template-sweet-gtk";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.sassc
          ];
          text = ''
            cache="''${XDG_CACHE_HOME:-$HOME/.cache}/noctalia/sweet"
            theme="''${XDG_DATA_HOME:-$HOME/.local/share}/themes/Sweet-Noctalia"

            if [ ! -f "$cache/_colors.scss" ]; then
              echo "noctalia-template-sweet-gtk: $cache/_colors.scss missing" >&2
              exit 1
            fi

            if [ -e "$theme" ]; then
              chmod -R u+w "$theme"
              rm -rf "$theme"
            fi
            mkdir -p "$theme"
            cp -r --no-preserve=mode ${inputs.sweet}/gtk-3.0 ${inputs.sweet}/gtk-4.0 ${inputs.sweet}/assets "$theme/"
            cp --no-preserve=mode ${inputs.sweet}/index.theme "$theme/"

            for toolkit in gtk-3.0 gtk-4.0; do
              cp "$cache/_colors.scss" "$theme/$toolkit/"
              cp --no-preserve=mode ${localTemplates}/sweet/_window-inset.scss "$theme/$toolkit/"
              printf "\n@import 'window-inset';\n" >> "$theme/$toolkit/gtk-dark.scss"
              sassc "$theme/$toolkit/gtk-dark.scss" "$theme/$toolkit/gtk-dark.css"
              # Only the dark entry point is built; both names resolve to it.
              cp "$theme/$toolkit/gtk-dark.css" "$theme/$toolkit/gtk.css"
            done

            # GTK reads the theme name from settings; cycling it makes running apps re-read.
            gsettings set org.gnome.desktop.interface gtk-theme "" || true
            gsettings set org.gnome.desktop.interface gtk-theme Sweet-Noctalia || true
          '';
        };
      };

      # Built-in rows: [dir file] from the noctalia package. `script` runs the template's apply.sh; `action` is a Noctalia post action.
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
          id = "wezterm";
          dir = "wezterm";
          file = "wezterm.toml";
          out = "$XDG_CONFIG_HOME/wezterm/colors/Noctalia.toml";
        }
        {
          # Upstream's reload.sh only pokes the running instance (config edit stripped).
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
          id = "pywalfox";
          dir = "pywalfox";
          file = "pywalfox.json";
          out = "$XDG_CACHE_HOME/wal/colors.json";
          action = "firefox-theme";
        }
        {
          # Moved out of the package's builtin rows in Noctalia 5.4.0.
          id = "starship";
          dir = "starship";
          file = "starship.toml";
          out = "$XDG_CACHE_HOME/noctalia/starship-palette.toml";
        }
        {
          id = "tmux";
          dir = "tmux";
          file = "tmux.conf";
          out = "$XDG_CONFIG_HOME/tmux/themes/noctalia.conf";
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

      # Rows become template entries; `root` is the input their paths are relative to.
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
          # Vendored from Noctalia 5.3.0; Umbriel includes the output (see umbriel.nix).
          umbriel = {
            input_path = "${localTemplates}/umbriel.toml";
            output_path = "$XDG_CONFIG_HOME/umbriel/noctalia.toml";
          };
          # Vendored from the community templates; see the header in the file.
          vicinae = {
            input_path = "${localTemplates}/vicinae.toml";
            output_path = "$XDG_DATA_HOME/vicinae/themes/noctalia.toml";
          };
          # fastfetch's config is the template itself: Noctalia renders the whole file.
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
          # Local fork: base0C/0D/0E take the bright tonal tier; upstream's *_fixed_dim roles equal the base roles.
          # ~/.config/nvim is read-only, so the palette renders to the cache and colors/noctalia.lua dofiles it.
          neovim = {
            input_path = "${localTemplates}/neovim.lua";
            output_path = "$XDG_CACHE_HOME/noctalia/nvim-palette.lua";
            post_hook = "${pkgs.procps}/bin/pkill -SIGUSR1 -x nvim || true";
          };
          # fzf's palette, mapped the way the pi theme maps it: roles rather than the
          # terminal's ANSI slots, so the selected-row band comes from the surface
          # scale and the frame from `outline`. fzf re-reads this file per invocation,
          # so a wallpaper change reaches it without a new shell.
          fzf = {
            input_path = "${localTemplates}/fzf.opts";
            output_path = "$XDG_CONFIG_HOME/fzf/themes/noctalia.opts";
          };
          # Radar's lifecycle roles mapped onto Noctalia's roles; rendered to its own
          # file because Radar's config.toml is Nix-owned.
          agent-radar = {
            input_path = "${localTemplates}/agent-radar.toml";
            output_path = "$XDG_CONFIG_HOME/radar/theme.toml";
          };
          # Sweet's palette partials. Both hooks rebuild the theme, so the order the
          # engine renders them in cannot matter.
          sweet-colors = {
            input_path = "${localTemplates}/sweet/_colors.scss";
            output_path = "$XDG_CACHE_HOME/noctalia/sweet/_colors.scss";
            post_hook = "${templateHooks.sweet}/bin/noctalia-template-sweet-gtk";
          };
          # libadwaita takes the palette through CSS variables; Sweet cannot, because
          # its compiled CSS bakes colours in. Rendering here touches no build.
          sweet-libadwaita = {
            input_path = "${localTemplates}/sweet/libadwaita.css";
            output_path = "$XDG_CONFIG_HOME/gtk-4.0/gtk.css";
          };
        };

      # Packaged seed for the mutable wallpaper. Copied into the user home only
      # when absent (tmpfiles `C`, not `C+`), so a runtime-edited wallpaper survives
      # switches. The packaged source is PNG where the destination ends in `.jpg`.
      wallpaperSeed = pkgs.nixos-artwork.wallpapers.nineish-dark-gray.gnomeFilePath;

    in
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      # Not xdg.dataFile, which would store-link the wallpaper. `C` copies the seed only when absent.
      systemd.user.tmpfiles.rules = [
        "d %h/.local/share/wallpapers 0755 - - -"
        # fzf refuses a missing FZF_DEFAULT_OPTS_FILE; Noctalia overwrites this on
        # every palette render.
        "d %h/.config/fzf/themes 0755 - - -"
        "f %h/.config/fzf/themes/noctalia.opts 0644 - - -"
        "C %h/.local/share/wallpapers/wallpapersden.com_colorful-textured-abstract_3840x2160.jpg 0644 - - - ${wallpaperSeed}"
      ];

      # niri rejects a second binds node in one file, so shell binds go in their own included file.
      xdg.configFile."niri/noctalia.kdl" =
        lib.mkIf (config ? wayland.windowManager.niri && config.wayland.windowManager.niri.enable)
          {
            text = ''
              spawn-at-startup "noctalia"
              spawn-at-startup "noctalia-action-bar-init"

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
                Mod+A hotkey-overlay-title="Toggle Action Bar" {
                  spawn "noctalia" "msg" "bar-toggle" "action";
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

            # Upstream's catalogues are off: the rows below are the whole set and
            # nothing downloads at apply time. Each row also sets the input filter.
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
              scroll_up = "workspace-switch prev";
              scroll_down = "workspace-switch next";
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
                  "workspaces"
                  "active_window"
                ];
                opacity = 0.06;
                padding = 9.0;
              }
            ];
          };

          bar.action = {
            position = "bottom";
            layer = "overlay";
            # No layout reservation: the bar draws over windows instead of
            # pushing them, so showing it never reflows the workspace.
            reserve_space = false;
            # Read at instance creation, so hotplugged monitors start hidden; `noctalia-action-bar-init` clears it on existing ones.
            auto_hide = true;
            background_opacity = 0.92;
            capsule_fill = "surface";
            capsule_foreground = "on_surface";
            capsule_opacity = 0.06;
            capsule_padding = 17.0;
            color = "secondary";
            contact_shadow = true;
            font_weight = 600;
            hover_highlight = false;
            icon_color = "tertiary";
            # Kept clear of the bottom edge by more than the auto-hide trigger
            # strip so a resting pointer never lands on it.
            margin_edge = 20;
            margin_ends = 26;
            padding = 16;
            radius = 18;
            scale = 2.0;
            shadow = true;
            thickness = 76;
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
                  "elijaharch/wl-screen-mirror:mirror"
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

          location.auto_locate = true;

          lockscreen_widgets.enabled = false;

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

            workspaces = {
              style = "focus_hint";
              label_source = "name";
              max_label_chars = 6;
              show_icons = false;
            };

            bar = {
              type = "noctalia/world_clock:bar";
            };

            "salemsayed/codexbar-meter:bar" = {
              enabled = true;
              scale = 1.3;
            };
          };

          plugin_settings = {
            "icefish/phone-connect".device_alias = "OnePlus 15";
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
              "salemsayed/codexbar-meter"
              "lux/ideapad-conservation-mode"
              "kenn/keybind-cheatsheet"
              "icefish/phone-connect"
              "elijaharch/wl-screen-mirror"
              "noctalia/world_clock"
              "noctalia/notes"
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
        # Template hook dependencies, resolved through the noctalia daemon's PATH:
        # `zip` for the libreoffice hook.
        pkgs.zip
        # icefish/phone-connect shells out to gdbus.
        pkgs.glib.bin
        noctaliaGreeterPackage
        # Config `auto_hide` also arms a hover reveal, so the running instances
        # are switched back to toggle-only here.
        (pkgs.writeShellApplication {
          name = "noctalia-action-bar-init";
          runtimeInputs = [
            pkgs.coreutils
            pkgs.noctalia
          ];
          text = ''
            for _ in {1..50}; do
              if noctalia msg bar-auto-hide-set off action >/dev/null 2>&1; then
                # `off` reveals a hidden bar, so hide it again straight away;
                # bar-hide cancels the reveal animation rather than waiting.
                noctalia msg bar-hide action >/dev/null 2>&1
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
