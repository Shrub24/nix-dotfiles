{ inputs, ... }:
{
  flake.modules.homeManager.herdr =
    { pkgs, ... }:
    {
      programs.herdr.package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.herdr;

      # Rendered to $XDG_CONFIG_HOME/herdr/config.toml; the rest of that directory
      # is Herdr-owned runtime state and stays unmanaged.
      #
      # Herdr rewrites this file when its UI changes a persisted setting, so a UI
      # edit has to be ported back here.
      programs.herdr.settings = {
        onboarding = false;
        theme = {
          name = "terminal";
          auto_switch = false;
        };
        ui = {
          status_indicators = "symbols";
          show_agent_labels_on_pane_borders = true;
          toast.delivery = "system";
          sidebar.agents.rows = [
            [
              "state_icon"
              "workspace"
              "tab"
            ]
            [
              "agent"
              "state_text"
            ]
          ];
        };
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
          # reviewr: diff review pane beside the chat
          {
            key = "alt+r";
            type = "plugin_action";
            command = "persiyanov.reviewr.toggle";
            description = "reviewr: diff review pane";
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
        ];
      };
    };
}
