{ inputs, ... }:
{
  flake-file.inputs.herdr-radar = {
    url = "github:Shrub24/herdr-radar";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.modules.homeManager.herdr =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      imports = [ inputs.herdr-radar.homeManagerModules.default ];

      programs.herdr.package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;

      # Relinked on every activation: Herdr's plugin registry is mutable state.
      programs.herdr-radar = {
        enable = true;
        herdrPackage = config.programs.herdr.package;
        settings.anchors = {
          auto_create = true;
          command = "${pkgs.runtimeShell} -c 'exec yazi'";
        };
      };

      home.packages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.hunk
      ];

      # Seeded as a real file at activation, not linked: Herdr and herdr-radar rename
      # temp files over it, which fails with EACCES on a store link. A switch
      # re-seeds these keys; anything else written here is machine-local.
      programs.herdr.settings = {
        onboarding = false;
        theme = {
          name = "terminal";
          auto_switch = false;
          # Declared so the plugin skips its theme block; the theme is ours (see context/herdr.md).
          custom.active_row_bg = "#414868";
        };
        ui = {
          status_indicators = "symbols";
          show_agent_labels_on_pane_borders = true;
          toast.delivery = "system";
          sidebar_max_width = 48;
        };
        # Prefix: herdr default (ctrl+b); shift+space cannot be captured.
        # Action ids are <plugin_id>.<action_id>; herdr binds none by default.
        # Navigation goes through smart-splits.nvim's herdr plugin (the same
        # plugin that drives the Neovim side), so ctrl+hjkl works identically
        # inside and outside a buffer. Resize is native herdr.
        keys.resize_pane_left = "alt+h";
        keys.resize_pane_down = "alt+j";
        keys.resize_pane_up = "alt+k";
        keys.resize_pane_right = "alt+l";
        keys.command = [
          # herdr-scratch: persistent workspace-scoped popup shell (herdr
          # native popup — ctrl+b q hides it, state survives toggle).
          {
            key = "prefix+p";
            type = "plugin_action";
            command = "herdr.scratch.toggle";
            description = "toggle scratch popup";
          }
          # herdr-nvim sidebar as a zoomed full-screen pane (toggle).
          {
            key = "prefix+n";
            type = "shell";
            command = "${pkgs.herdr-nvim-zoom}/bin/herdr-nvim-zoom";
            description = "nvim fullscreen toggle (zoomed sidebar)";
          }
          # Full-pane tool launchers (popups).
          {
            key = "prefix+j";
            type = "popup";
            width = "80%";
            height = "85%";
            command = "jjui";
            description = "jjui (popup)";
          }
          {
            key = "prefix+r";
            type = "popup";
            width = "80%";
            height = "85%";
            command = "${
              inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.hunk
            }/bin/hunk diff --vcs jj";
            description = "hunk code review (popup)";
          }
          {
            key = "ctrl+h";
            type = "plugin_action";
            command = "smart-splits.nvim.left";
            description = "navigate left (nvim-aware)";
          }
          {
            key = "ctrl+j";
            type = "plugin_action";
            command = "smart-splits.nvim.down";
            description = "navigate down (nvim-aware)";
          }
          {
            key = "ctrl+k";
            type = "plugin_action";
            command = "smart-splits.nvim.up";
            description = "navigate up (nvim-aware)";
          }
          {
            key = "ctrl+l";
            type = "plugin_action";
            command = "smart-splits.nvim.right";
            description = "navigate right (nvim-aware)";
          }
          {
            key = "prefix+t";
            type = "plugin_action";
            command = "herdr-navigator.open";
            description = "navigator: fuzzy jump (workspace/agent/project/session/dir)";
          }
          {
            key = "prefix+l";
            type = "plugin_action";
            command = "herdr-navigator.jump-back";
            description = "navigator: jump back";
          }
          {
            key = "prefix+k";
            type = "plugin_action";
            command = "herdr-bar.open";
            description = "jump bar: fuzzy tab/pane/agent";
          }
          {
            key = "prefix+up";
            type = "plugin_action";
            command = "cloudmanic.herdr-plus.projects";
            description = "projects: new workspace from template";
          }
          {
            key = "prefix+down";
            type = "plugin_action";
            command = "cloudmanic.herdr-plus.quick-actions";
            description = "quick actions: fuzzy script launcher";
          }
          {
            key = "prefix+e";
            type = "plugin_action";
            command = "chmarax.herdr-nvim.toggle";
            description = "nvim sidebar toggle";
          }
          {
            key = "prefix+o";
            type = "plugin_action";
            command = "chmarax.herdr-nvim.pick-file";
            description = "nvim: open file from agent output";
          }
          {
            key = "prefix+a";
            type = "plugin_action";
            command = "annotate.capture";
            description = "annotate selection";
          }
          {
            key = "prefix+f";
            type = "plugin_action";
            command = "youguanxinqing.herdr-flash.flash";
            description = "flash: search + yank visible text";
          }
          # memex session desk; needs `herdr plugin install Shrub24/memex` once,
          # which reuses the memex already on PATH.
          {
            key = "prefix+m";
            type = "plugin_action";
            command = "nicosuave.memex.palette";
            description = "memex: session palette";
          }
          # Cycles herdr-radar's Agents panel order; Herdr's grouped/priority toggle is disabled while this is active.
          {
            key = "prefix+v";
            type = "plugin_action";
            command = "hhdebb.herdr-radar.view-toggle";
            description = "agents panel: cycle order (active / recent / off)";
          }
        ];
      };

      xdg.configFile."herdr/config.toml".enable = false;
      home.activation.herdrConfig =
        lib.hm.dag.entryAfter
          ([ "writeBoundary" ] ++ lib.optional config.programs.herdr-radar.enable "linkHerdrRadar")
          ''
            ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/herdr"
            # Renamed into place: the old path is a store symlink, which a write would follow.
            ${pkgs.coreutils}/bin/install -m 0644 \
              ${(pkgs.formats.toml { }).generate "herdr-config.toml" config.programs.herdr.settings} \
              "$HOME/.config/herdr/config.toml.new"
            ${pkgs.coreutils}/bin/mv -f "$HOME/.config/herdr/config.toml.new" "$HOME/.config/herdr/config.toml"

            # The seed replaces the whole file, so radar re-merges its own blocks.
            # A refusal (a config that does not parse) aborts the switch.
            ${config.programs.herdr-radar.package}/bin/configure.js --apply
            # Layouts and themes are client-side (prefix+shift+r); this reloads the server.
            ${lib.getExe config.programs.herdr.package} server reload-config || true
          '';
    };
}
