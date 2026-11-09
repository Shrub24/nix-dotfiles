{ inputs, ... }:
{
  # Umbriel's cache only matches its own locked nixpkgs, so the input does not follow ours.
  flake-file.inputs.umbriel.url = "github:noctalia-dev/umbriel";
  flake-file.nixConfig = {
    extra-substituters = [ "https://umbriel.cachix.org?priority=50" ];
    extra-trusted-public-keys = [ "umbriel.cachix.org-1:JfNq/2yg2S6D6z4Z2dVSZrZlDPQTKtexB6GAVLD98nw=" ];
  };

  flake.modules.nixos.umbriel =
    { pkgs, ... }:
    let
      packages = inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      programs.uwsm.waylandCompositors.umbriel = {
        prettyName = "Umbriel";
        comment = "Umbriel managed by UWSM";
        binPath = "${packages.default}/bin/umbriel";
      };
      # uwsm prints its start messages to the greetd VT, which shows as a flash at login.
      environment.sessionVariables.UWSM_SILENT_START = "1";
    };

  flake.modules.homeManager.umbriel =
    { lib, pkgs, ... }:
    let
      packages = inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system};
      directions = {
        Left = "left";
        Down = "down";
        Up = "up";
        Right = "right";
        H = "left";
        J = "down";
        K = "up";
        L = "right";
      };
      directional =
        prefix: action:
        lib.mapAttrs' (key: dir: lib.nameValuePair "${prefix}+${key}" "${action}-${dir}") directions;
      # The binary UWSM launches; effect shaders are included from this build, not
      # from whatever `programs.umbriel.package` happens to resolve to.
      umbrielPkg = inputs.umbriel.packages.${pkgs.stdenv.hostPlatform.system}.default;
      workspaces = lib.genAttrs (map toString (lib.range 1 9)) (n: n);
      workspaceBinds = lib.mapAttrs' (
        n: _: lib.nameValuePair "Mod+${n}" "workspace-switch ${n}"
      ) workspaces;
      moveWorkspaceBinds = lib.mapAttrs' (
        n: _: lib.nameValuePair "Mod+Shift+${n}" "column-move-to-workspace ${n}"
      ) workspaces;
    in
    {
      imports = [ inputs.umbriel.homeModules.default ];
      home.packages = [
        pkgs.wdisplays
        inputs.vicinae-extensions.packages.${pkgs.stdenv.hostPlatform.system}.cli
      ];
      # Umbriel ships no completions; this is generated from its own help output.
      xdg.configFile."fish/completions/umbriel.fish".source = "${pkgs.umbriel-completions}/umbriel.fish";
      # shikane only re-evaluates on a change it notices; after a replug it can
      # stay on a stale head set and never apply the profile for the displays
      # that are actually connected. Watching the compositor's own output events
      # and reloading closes that gap without restarting the daemon.
      systemd.user.services.shikane-reload = {
        Unit = {
          Description = "Re-apply the shikane profile after an output change";
          PartOf = [ "wayland-wm@umbriel.service" ];
          After = [ "wayland-wm@umbriel.service" ];
        };
        Service = {
          ExecStart = lib.getExe (
            pkgs.writeShellApplication {
              name = "shikane-reload";
              runtimeInputs = [
                pkgs.coreutils
                pkgs.gnugrep
                pkgs.jq
                pkgs.shikane
                pkgs.systemd
                umbrielPkg
              ];
              # A replug, and a dock even more so, connects several displays in
              # one go and goes quiet between them; applying into that window is
              # what gets an atomic commit refused. So the trigger is the output
              # state holding still, not the events stopping: one apply per
              # settled arrangement.
              #
              # Reloading is not always enough either. When an apply is refused —
              # a DRM atomic commit can fail with EBUSY while a connector settles —
              # the daemon keeps a variant that never completes: its journal then
              # ends at VariantInProgress, every later apply is refused as well,
              # and a reload cannot clear it. A restart reads the same
              # configuration and does, so the daemon's own state decides between
              # the two.
              text = ''
                # Answer a burst of connects once rather than once per connect,
                # and only after the arrangement has held still for two seconds:
                # a dock attaches its displays over several of them.
                settle() {
                  previous=""
                  stable=0
                  for _ in $(seq 1 15); do
                    current=$(umbriel outputs --json | jq -c '
                      [.[] | {name, enabled, scale, position,
                              mode: ([.modes[] | select(.current) | .refresh_mhz] | first)}]
                      | sort_by(.name)')
                    if [ "$current" = "$previous" ]; then
                      stable=$((stable + 1))
                      if [ "$stable" -ge 2 ]; then
                        return 0
                      fi
                    else
                      stable=0
                    fi
                    previous="$current"
                    sleep 1
                  done
                }

                cooldown=0
                umbriel subscribe outputs | while IFS= read -r _; do
                  echo "output change noticed; waiting for the arrangement to settle" >&2
                  settle
                  # Events raised while settling belong to this connection.
                  while IFS= read -r -t 0.2 _; do :; done
                  # Applying the profile emits output events as well; ignoring
                  # them keeps the recovery from retriggering itself.
                  if [ "$(date +%s)" -lt "$cooldown" ]; then
                    continue
                  fi
                  echo "reloading the shikane profile" >&2
                  since=$(date '+%Y-%m-%d %H:%M:%S')
                  shikanectl reload >/dev/null 2>&1 || true
                  sleep 3
                  state=$(journalctl --user -u shikane --since "$since" --no-pager 2>/dev/null \
                    | grep -o 'New daemon state: [A-Za-z]*' | tail -n 1 || true)
                  # Both states that mean the daemon finished end in
                  # "VariantApplied"; a pending variant ends in "VariantInProgress".
                  case "$state" in
                    *VariantApplied) ;;
                    *)
                      echo "no variant finished after the reload (last state: ''${state:-none}); restarting shikane" >&2
                      systemctl --user restart shikane || true
                      ;;
                  esac
                  cooldown=$(( $(date +%s) + 5 ))
                done
              '';
            }
          );
          Restart = "always";
          RestartSec = 2;
        };
        Install.WantedBy = [ "wayland-wm@umbriel.service" ];
      };
      services.shikane = {
        enable = true;
        settings =
          let
            out =
              serial: mode: position: scale: extra:
              {
                search = "[s=]${serial}";
                enable = true;
                inherit mode position scale;
              }
              // extra;
            edp = out "0x00000005" "2560x1600@240Hz";
            # A display joining an arrangement takes whatever wallpaper the other
            # outputs already show, because Noctalia applies a wallpaper to every
            # connected output. Re-applying the current one rather than advancing
            # the rotation keeps that working without making each re-apply — and
            # each restart of the daemon — change the wallpaper.
            reapplyWallpaper = lib.getExe (
              pkgs.writeShellApplication {
                name = "shikane-wallpaper-reapply";
                runtimeInputs = [ pkgs.noctalia ];
                text = ''
                  noctalia msg wallpaper-set "$(noctalia msg wallpaper-get)"
                '';
              }
            );
            profile = name: output: {
              inherit name output;
              exec = [ reapplyWallpaper ];
            };
            deskPair = [
              (out "0x00000005" "2560x1600@240.002Hz" "0,290" 1.6484375 {
                search = [
                  "m=0x0BBE"
                  "s=0x00000005"
                  "v=BOE"
                ];
                transform = "normal";
                adaptive_sync = true;
              })
              (out "XK5R8JA000154" "3840x2160@160Hz" "1553,0" 1.44921875 {
                search = [
                  "m=U32G4"
                  "s=XK5R8JA000154"
                  "v=AOC"
                ];
                transform = "normal";
                adaptive_sync = true;
              })
            ];
          in
          {
            profile = [
              (profile "desk" (
                deskPair
                ++ [
                  (out "2S5S5HA013088" "2560x1440@144.001Hz" "4203,180" 1.25 {
                    search = [
                      "m=Q27G40E"
                      "s=2S5S5HA013088"
                      "v=AOC"
                    ];
                    transform = "normal";
                    # The compositor rejects the whole desk arrangement while
                    # VRR is requested on this panel, so it stays off here.
                    adaptive_sync = false;
                  })
                ]
              ))
              (profile "2x-desk" deskPair)
              (profile "undocked" [ (edp "0,0" 1.3 { adaptive_sync = true; }) ])
            ];
          };
      };
      # Wanted by the Umbriel session's UWSM unit only, so Niri sessions never run it.
      systemd.user.services.shikane.Install.WantedBy = lib.mkForce [ "wayland-wm@umbriel.service" ];

      xdg.desktopEntries.screenshot = {
        name = "Screenshot";
        comment = "Capture a region, window or output, or hand a capture to OCR, Lens or KDE Connect";
        exec = "vicinae cmd launch @saurabhj/screenshot-extension:capture";
        icon = "accessories-screenshot";
        categories = [ "Utility" ];
      };

      xdg.portal.config.umbriel = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "termfilechooser" ];
        "org.freedesktop.impl.portal.Settings" = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "umbriel" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "umbriel" ];
      };
      # The ScreenCast/Screenshot mapping names this backend, so it must be
      # installed where the session's frontend looks: Home Manager, not the
      # NixOS-side list, which is inert while xdg.portal is disabled there.
      xdg.portal.extraPortals = [ packages.xdg-desktop-portal-umbriel ];
      systemd.user.packages = [ packages.xdg-desktop-portal-umbriel ];

      programs.umbriel = {
        enable = true;
        package = umbrielPkg;
        settings = {
          # The palette is rendered by Noctalia; optional so the file can appear later.
          include.optional.files = [ "noctalia.toml" ];
          # Shipped preset, selected below; the path follows the running build.
          include.files = [
            "${umbrielPkg}/share/umbriel/effects/animation/workspace_wipe/effect.toml"
          ];
          general = {
            autostart = [
              "uwsm finalize"
              "noctalia"
              "noctalia-action-bar-init"
            ];
            show_cheatsheet = false;
            # An app asking for attention (xdg-activation, e.g. a URL opened from
            # kitty) reveals and focuses its window, as it did under niri.
            focus_on_activate = true;
          };
          # Mode, position and scale come from the shikane profiles; focus and workspace placement follow the main display by presence.
          # VRR stays on for the two main panels. The 27" is left off: the
          # compositor rejects the desk arrangement while VRR is requested there.
          output =
            lib.genAttrs [ "AOC U32G4 1322131231233" "AOC U32G4 XK5R8JA000154" ] (_: {
              focus_at_startup = true;
              workspaces = [
                "home"
                "dev"
                "mb"
              ];
              vrr = "always";
            })
            // {
              "BOE 0x0BBE 0x00000005".vrr = "always";
            };
          # Trial: avoid wlroots' failing multi-GPU hardware-cursor format negotiation.
          input.cursor = {
            theme = "Bibata-Rainbow-Modern";
            size = 26;
            hardware_cursor = false;
          };
          input.keyboard = {
            layout = "au,gb";
            numlock_toggle = true;
          };
          layout = {
            mode = "scrolling";
            gap = 5;
            extent_presets = [
              0.33333
              0.5
              0.66667
            ];
            scrolling = {
              default_extent_fraction = 0.5;
              center_focused = "never";
              center_underfull_strip = false;
            };
            tabs.default_display = "tabbed";
          };
          appearance = {
            prefer_no_csd = true;
            border_width = 0;
            corner_radius = 24;
            # Frosted rather than merely softened: a wide radius with visible
            # grain, held back in brightness so the layer reads as glass.
            blur = {
              enabled = true;
              passes = 3;
              radius = 6;
              noise = 0.02;
              saturation = 0.85;
              contrast = 0.85;
            };
            shadow = {
              enabled = true;
              softness = 30;
              offset_x = 0;
              offset_y = 5;
            };
            tab_bar = {
              style = "indicator";
              hide_when_single = true;
            };
          };
          # The focused outline comes from the Noctalia palette; unfocused windows
          # carry no outline at all.
          colors.border.unfocused = "#00000000";

          # Fast but fluid: springs reach the target without overshoot, so short
          # settles read as responsive rather than abrupt.
          # Flowy and minimal: eased fades rather than springs, so nothing
          # overshoots, and only the workspace change moves anything.
          animation = {
            enabled = true;
            duration_ms = 220;
            curve = "easeout";
            windows_in = {
              style = "popin";
              scale = 0.96;
              duration_ms = 200;
              curve = "easeout";
            };
            windows_out = {
              style = "fade";
              duration_ms = 160;
              curve = "easeout";
            };
            # Damping 1 settles without overshoot; the stiffness sets how softly.
            windows_move.curve = "spring:1,900";
            windows_resize.curve = "spring:1,900";
            # Both workspaces stay put and the shader wipes between them.
            workspaces = {
              style = "reveal";
              effect = "workspace_wipe";
              duration_ms = 280;
              curve = "easeout";
            };
            overview = {
              curve = "spring:1,850";
              workspace_curve = "spring:1,950";
            };
            scratchpad = {
              curve = "spring:1,900";
              dim = 0.35;
            };
            dialogs.dim = 0.25;
            border.curve = "spring:1,900";
          };
          window_rule = [
            { blur = true; }
            {
              # No outline on anything but the focused window.
              match.is_focused = false;
              opacity = 0.82;
            }
            {
              # More opaque than the rest, so the focused window keeps its
              # foreground legible over the heavier blur behind it.
              match.is_focused = true;
              opacity = 0.92;
              border_width = 2;
            }
            {
              match = {
                app_id = [
                  "firefox"
                  "okular"
                  "libreoffice"
                ];
                is_focused = false;
              };
              opacity = 0.85;
            }
            {
              match.app_id = [
                "^gnome-calculator$"
                "^galculator$"
                "^blueman-manager$"
              ];
              default_floating = true;
            }
            {
              match.title = "^(Picture-in-Picture|Picture in picture)$";
              default_floating = true;
              default_maximize = false;
              default_position = {
                x = 20;
                y = 20;
                anchor = "bottom_right";
              };
            }
            # The portal file chooser arrives as its own application, with nothing
            # naming the window that asked for it, so it is floated and centred here.
            {
              match.app_id = "^yazi-chooser$";
              default_floating = true;
              default_focused = true;
              default_floating_size = {
                width = 0.8;
                height = 0.8;
              };
              default_position = {
                x = 0;
                y = 0;
                anchor = "center";
              };
            }
            {
              match.app_id = "^dev.noctalia.Noctalia$";
              default_floating = true;
              default_floating_size_px = {
                width = 1080;
                height = 920;
              };
            }
            {
              match.is_cast_target = true;
              border_color_focused = "#f38ba8ff";
              border_color_unfocused = "#7d0d2dff";
            }
          ];
          layer_rule = [
            {
              match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd|desktop-widget-[^\"]*)$";
              blur = true;
              blur_ignore_alpha = 0.5;
              blur_popups = true;
            }
            {
              match.namespace = "^noctalia-(notification|dock|panel|attached-panel|osd)$";
              blur_optimized = false;
            }
            # The launcher re-blurs the live scene each frame: its cached backdrop
            # lags behind scrolling content underneath it.
            {
              match.namespace = "^vicinae";
              blur = true;
              # The rounded corners are transparent; without a threshold their
              # blur fills the square behind them.
              blur_ignore_alpha = 0.1;
              blur_optimized = false;
              blur_popups = true;
            }
          ];
          keybinds =
            workspaceBinds
            // moveWorkspaceBinds
            // directional "Mod" "window-focus"
            // directional "Mod+Alt" "output-focus"
            // directional "Mod+Shift+Ctrl" "column-move-to-output"
            // {
              "Mod+Shift+Left" = "column-move-left";
              "Mod+Shift+H" = "column-move-left";
              "Mod+Shift+Right" = "column-move-right";
              "Mod+Shift+L" = "column-move-right";
              "Mod+Shift+Down" = "window-move-down";
              "Mod+Shift+J" = "window-move-down";
              "Mod+Shift+Up" = "window-move-up";
              "Mod+Shift+K" = "window-move-up";
              "Mod+D" = "overview-toggle";
              "Mod+Tab" = "overview-toggle";
              "Mod+Shift+Slash" = "cheatsheet-toggle";
              "Mod+T" = "spawn kitty";
              "Mod+E" = "spawn dolphin";
              "Mod+Space" = "spawn uwsm app -- vicinae toggle";
              "Mod+V" = "spawn uwsm app -- vicinae vicinae://launch/clipboard/history";
              "Mod+U" = "spawn vicinae cmd launch @saurabhj/windows-extension:windows";
              "Mod+Slash" = "spawn uwsm app -- vicinae vicinae://launch/file/search";
              "Mod+Shift+E" = "session-quit";
              "Mod+Q" = "window-close";
              "Mod+F" = "window-toggle-maximize";
              "Mod+Shift+F" = "window-toggle-fullscreen";
              "Mod+Alt+F" = "window-toggle-maximize-to-edges";
              "Mod+Shift+Y" = "window-toggle-scratchpad";
              "Mod+Shift+G" = "scratchpad-toggle";
              "Mod+Shift+T" = "window-toggle-floating";
              "Mod+Shift+V" = "window-focus-switch-floating";
              "Mod+W" = "column-toggle-tabbed";
              "Mod+Home" = "column-focus-first";
              "Mod+End" = "column-focus-last";
              "Mod+Ctrl+Home" = "column-move-to-first";
              "Mod+Ctrl+End" = "column-move-to-last";
              "Mod+Alt+Page_Up" = "column-move-to-output-left";
              "Mod+Alt+Page_Down" = "column-move-to-output-right";
              "Mod+Page_Down" = "workspace-next";
              "Mod+Page_Up" = "workspace-previous";
              "Mod+Ctrl+Page_Down" = "column-move-to-workspace-next";
              "Mod+Ctrl+Page_Up" = "column-move-to-workspace-previous";
              "Mod+Ctrl+J" = "column-move-to-workspace-next";
              "Mod+Ctrl+K" = "column-move-to-workspace-previous";
              "Mod+Ctrl+Down" = "column-move-to-workspace-next";
              "Mod+Ctrl+Up" = "column-move-to-workspace-previous";
              "Mod+Ctrl+U" = "column-move-to-workspace-next";
              "Mod+Ctrl+I" = "column-move-to-workspace-previous";
              "Mod+Shift+Page_Down" = "workspace-move-down";
              "Mod+Shift+Page_Up" = "workspace-move-up";
              "Mod+Shift+U" = "workspace-move-down";
              "Mod+Shift+I" = "workspace-move-up";
              "Mod+WheelDown" = "workspace-next";
              "Mod+WheelUp" = "workspace-previous";
              "Mod+Ctrl+WheelDown" = "column-move-to-workspace-next";
              "Mod+Ctrl+WheelUp" = "column-move-to-workspace-previous";
              "Mod+Shift+WheelDown" = "window-focus-right";
              "Mod+Shift+WheelUp" = "window-focus-left";
              "Mod+Ctrl+Shift+WheelDown" = "column-move-right";
              "Mod+Ctrl+Shift+WheelUp" = "column-move-left";
              "Mod+BracketLeft" = "window-consume-or-expel-left";
              "Mod+BracketRight" = "window-consume-or-expel-right";
              "Mod+R" = "window-cycle-primary-extent";
              "Mod+Shift+R" = "window-cycle-secondary-extent";
              "Mod+C" = "column-center";
              "Mod+Ctrl+F" = "window-toggle-maximize";
              "Mod+Minus" = "window-modify-primary-extent -0.1";
              "Mod+Equal" = "window-modify-primary-extent +0.1";
              "Mod+Shift+Minus" = "window-modify-secondary-extent -0.1";
              "Mod+Shift+Equal" = "window-modify-secondary-extent +0.1";
              "Mod+Escape" = {
                action = "shortcuts-inhibit-toggle";
                allow_when_inhibited = true;
              };
              "Mod+Shift+P" = "dpms-off";
              "Ctrl+Alt+Space" = "keyboard-layout-next";
              "Mod+A" = "spawn noctalia msg bar-toggle action";
              "Mod+Comma" = "spawn noctalia msg settings-toggle";
              "Mod+N" = "spawn noctalia msg panel-toggle control-center";
              "Mod+Y" = "spawn noctalia msg wallpaper-next";
              "Ctrl+Alt+L" = "spawn noctalia msg session lock";
              # One key opens the launcher's screenshot view, which carries a row
              # and an action panel per mode; Print stays the fast path to a
              # region capture.
              "Mod+Shift+S" = "spawn vicinae cmd launch @saurabhj/screenshot-extension:capture";
              "Print" = "spawn screenshot region";
              "XF86AudioRaiseVolume" = {
                action = "spawn noctalia msg volume-up 3";
                allow_when_locked = true;
              };
              "XF86AudioLowerVolume" = {
                action = "spawn noctalia msg volume-down 3";
                allow_when_locked = true;
              };
              "XF86AudioMute" = {
                action = "spawn noctalia msg volume-mute";
                allow_when_locked = true;
              };
              "XF86AudioMicMute" = {
                action = "spawn noctalia msg mic-mute";
                allow_when_locked = true;
              };
              "XF86MonBrightnessUp" = {
                action = "spawn noctalia msg brightness-up";
                allow_when_locked = true;
              };
              "XF86MonBrightnessDown" = {
                action = "spawn noctalia msg brightness-down";
                allow_when_locked = true;
              };
            };
        };
      };
    };
}
