{
  inputs,
  ...
}:
{
  flake-file.inputs = {
    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Noctalia fetches community templates from api.noctalia.dev at runtime;
    # pinning the source repo keeps the template inputs declarative.
    community-templates = {
      url = "github:noctalia-dev/community-templates";
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
          id = "pywalfox";
          dir = "pywalfox";
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
          # ~/.config/nvim is read-only from the store, so the palette renders
          # to the cache and colors/noctalia.lua dofiles it.
          neovim = {
            input_path = "${localTemplates}/neovim.lua";
            output_path = "$XDG_CACHE_HOME/noctalia/nvim-palette.lua";
            post_hook = "${pkgs.procps}/bin/pkill -SIGUSR1 -x nvim || true";
          };
        };

      # Specialized at the feature use site: uid from the projected account.
      primaryUser = config.currentHost.primaryUser;

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

        # Upstream disables the HM module by filename ("programs/noctalia.nix"),
        # but home-manager turned it into a folder on 2026-09-30, so both copies
        # load and declare programs.noctalia twice. Until noctalia PR #4656
        # lands, disable the folder here too (the lists merge).
        { disabledModules = [ "programs/noctalia" ]; }
      ];

      # Bootstrap the mutable wallpaper directory + seed on first activation.
      # xdg.dataFile would store-link the destination and break runtime changes;
      # `d`+`C` create mutable paths under user ownership and copy the seed only
      # when absent. `C` (not `C+`) preserves a pre-existing wallpaper.
      systemd.user.tmpfiles.rules = [
        "d %h/.local/share/wallpapers 0755 - - -"
        "C %h/.local/share/wallpapers/wallpapersden.com_colorful-textured-abstract_3840x2160.jpg 0644 - - - ${wallpaperSeed}"
      ];

      # niri's KDL parser rejects a second binds node in one file, so shell binds render into noctalia-binds.kdl included below.
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
            position = "bottom";
            layer = "overlay";
            # No layout reservation: the bar draws over windows instead of
            # pushing them, so showing it never reflows the workspace.
            reserve_space = false;
            # New monitors build their own bar instance from the config, and
            # `bar-hide` only reaches instances that already exist — which is
            # why a hotplugged display showed both bars unbidden. `auto_hide` is
            # the one key read at instance creation, so every bar starts hidden
            # hidden on every monitor. Nothing else in config gives a
            # toggle-only bar, though: the same key also arms a 3px
            # bottom-edge hover reveal (`kAutoHideTriggerPx` is a hardcoded
            # constant, not a setting) and fades the bar out when the pointer
            # leaves. `noctalia-action-bar-init` takes auto-hide back off at
            # runtime for the instances that exist, leaving the config value
            # to do its job for instances built later.
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
            # Twice the default bar: 76px tall, widget content at 2x.
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
        # auto_hide is what makes an action-bar instance start hidden
        # (bar.cpp:3350), but the same key arms the bottom-edge hover reveal
        # and the hide-on-pointer-leave, so a config-only bar can never be
        # toggle-only. This clears auto-hide on the instances that exist and
        # puts them back under bar-toggle; the config value still applies to
        # instances created later, so a hotplugged display still starts hidden.
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
