{ omniroute, primaryUser }:
{
  config,
  lib,
  pkgs,
  ...
}:
{
  sops.templates."aichat.env".content = ''
    OMNIROUTE_API_KEY=${config.sops.placeholder.OMNIROUTE_API_KEY}
  '';

  home = {
    username = primaryUser.name;
    homeDirectory = "/home/${primaryUser.name}";
    stateVersion = "26.11";
    enableNixpkgsReleaseCheck = false;

    sessionVariables.AICHAT_ENV_FILE = config.sops.templates."aichat.env".path;

    packages = with pkgs; [
      marp-cli
    ];
  };

  programs = {
    home-manager.enable = true;

    pi-coding-agent.enable = true;
    herdr.enable = true;

    grist = {
      enable = true;
      administratorEmail = "jhanjeesaurabh@gmail.com";
      organizationSlug = "personal";
    };
    aichat = {
      enable = true;
      settings = {
        model = "omniroute:coder-high";
        clients = [
          {
            type = "openai-compatible";
            name = "omniroute";
            api_base = "${omniroute}/v1";
            models = [
              {
                name = "coder-high";
                max_input_tokens = 131072;
              }
            ];
          }
        ];
      };
    };
    lazyjournal = {
      enable = true;
    };
    qmd.enable = true;
    mcpNixos.enable = true;
    agentTools.enable = true;
    devTools.enable = true;
    webCatalog.enable = true;

    hermes-agent.enable = false;

    zsh.initContent = lib.mkAfter ''
      if [[ -z "$TMUX" ]] && { [[ -n "$SSH_CONNECTION" ]] || [[ -n "$MOSH_SERVER" ]]; }; then
        exec tmux new-session -A -s main
      fi
    '';

    miseTools = {
      enable = true;
      node = "lts";
      pnpm = "latest";
      bun = "latest";
    };

    # Desktop widgets calibrated to this machine's eDP-1 panel; the shared
    # noctalia aspect keeps no geometry.
    noctalia.settings.desktop_widgets = {
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
  };

  # This machine's external DP-1 and NVIDIA render node; the shared niri
  # aspect carries neither.
  wayland.windowManager.niri.settings = {
    debug."render-drm-device" = "/dev/dri/by-path/pci-0000:01:00.0-render";

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
    ];
  };

  services.hermes-agent = {
    enable = true;
    gateway.enable = true;
  };
}
