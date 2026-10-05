{ inputs, ... }:
{
  # The herdr-radar fork: `packages.default` is the plugin root Herdr registers,
  # `packages.herdr-anchor` the pane wrapper, and `homeManagerModules.default`
  # the module imported below.
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

      # The fork owns the plugin root, the anchor wrapper and the sidebar and
      # tab-bar blocks, so its module is the one that links and versions them:
      # `herdr plugin link` is the only way Herdr learns of a plugin and its
      # registry is mutable state, so the link is refreshed every activation.
      # nixpkgs carries no herdr, so the link target is the same package Herdr
      # itself comes from. `herdrPlus` stays off: its workspace templates are
      # layouts, and nothing here asks for them yet.
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

      # Rendered by Nix, then seeded into $XDG_CONFIG_HOME/herdr/config.toml as
      # a real file at activation (see home.activation.herdrConfig); the rest of
      # that directory is Herdr-owned runtime state and stays unmanaged.
      #
      # This file is the one place an application owns config here: Herdr writes
      # it whenever its UI persists a setting, and herdr-radar writes a
      # marker-fenced block into it. Both write through a temp file renamed over
      # the real path, which a read-only store symlink cannot serve: the link
      # resolves into /nix/store, the temp file lands beside the store path and
      # the install dies with EACCES. Hence a seeded file rather than a link.
      #
      # Anything Herdr or a plugin writes here is machine-local state, and a
      # switch re-seeds the published keys over it. One of the three blocks
      # herdr-radar installs is declared here instead — its theme tokens — and a
      # table in this file is a table it leaves alone, so it writes its sidebar
      # and tab-bar blocks itself and leaves the theme ours.
      programs.herdr.settings = {
        onboarding = false;
        theme = {
          name = "terminal";
          auto_switch = false;
          # Herdr's active-row fill. The plugin installs this token itself, but
          # it rewrites `theme.name` in the same write — `terminal` is neither a
          # light nor a dark built-in, so it substitutes catppuccin — and the
          # theme is ours to choose. Declaring the table makes the plugin skip
          # its theme block and leave both keys alone. The value is the plugin's
          # own dark chrome token.
          custom.active_row_bg = "#414868";
        };
        ui = {
          status_indicators = "symbols";
          show_agent_labels_on_pane_borders = true;
          toast.delivery = "system";
          sidebar_max_width = 48;
        };
        # Prefix: herdr default (ctrl+b) for now — shift+space proved
        # non-capturable in practice; revisit with a plugin later.
        # Plugin hotkeys — nvim-like movement, workspace jump, nvim sidebar.
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
          # Full-pane tool launchers (popups; singleton-tab revisit later
          # via a herdr plugin).
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
          # herdr-navigator: fuzzy jump anywhere + tmux-style jump-back
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
          # herdr-bar: fuzzy tab/pane/agent jump bar
          {
            key = "prefix+k";
            type = "plugin_action";
            command = "herdr-bar.open";
            description = "jump bar: fuzzy tab/pane/agent";
          }
          # herdr-plus: new workspace from template / quick actions
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
          # herdr-nvim: nvim sidebar + file picker
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
          # annotate + herdr-flash: selection tooling
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
          # herdr-radar: the Agents panel's order, off -> active -> recent and
          # round again. Herdr disables its own grouped/priority toggle while a
          # sort override is active, so this key is both the way in and the way
          # out. It leaves the panel's look alone, which is declared in Nix.
          {
            key = "prefix+v";
            type = "plugin_action";
            command = "hhdebb.herdr-radar.view-toggle";
            description = "agents panel: cycle order (active / recent / off)";
          }
        ];
      };

      # Home Manager would link the settings above read-only; that is the one
      # thing this file cannot be. Seeding it as a real file keeps the published
      # keys authoritative without freezing the file against Herdr's own writes.
      xdg.configFile."herdr/config.toml".enable = false;
      home.activation.herdrConfig =
        lib.hm.dag.entryAfter
          ([ "writeBoundary" ] ++ lib.optional config.programs.herdr-radar.enable "linkHerdrRadar")
          ''
            ${pkgs.coreutils}/bin/mkdir -p "$HOME/.config/herdr"
            # Written beside the target and renamed over it: the path is a store
            # symlink until this runs, and writing through one would land in the
            # store.
            ${pkgs.coreutils}/bin/install -m 0644 \
              ${(pkgs.formats.toml { }).generate "herdr-config.toml" config.programs.herdr.settings} \
              "$HOME/.config/herdr/config.toml.new"
            ${pkgs.coreutils}/bin/mv -f "$HOME/.config/herdr/config.toml.new" "$HOME/.config/herdr/config.toml"

            # The seed replaces the whole file, so radar's sidebar and tab-bar
            # blocks go back in through its own merge. A refusal (a config that
            # would not parse) aborts the switch; `|| true` here hid exactly that.
            ${config.programs.herdr-radar.package}/bin/configure.js --apply
            # Layouts and themes are client-side; a running Herdr picks them up
            # on prefix+shift+r, this reload covers the server half.
            ${lib.getExe config.programs.herdr.package} server reload-config || true
          '';
    };
}
