-- Ported from lua/plugins/snacks.lua.
--
-- The dashboard's four `LazyVim.pick*` action strings became direct
-- Snacks.picker calls — the only LazyVim API use in the whole config. Every
-- other option table is verbatim.
--
-- The inline snacks spec in init.lua is replaced by this file; `<leader>ga`
-- moved here with it.
return {
  {
    "snacks.nvim",
    auto_enable = true,
    lazy = false,
    keys = {
      {
        "<leader>ga",
        function()
          require("snacks").picker.git_status({
            title = "Audit Agent Changes",
            tree = true,
            on_show = function()
              vim.cmd.stopinsert()
            end,
            layout = { preset = "sidebar", preview = "main" },
            win = {
              input = { keys = { ["<Tab>"] = { "git_stage", mode = { "n", "i" } } } },
              preview = {
                minimal = false,
                wo = { signcolumn = "yes", cursorline = true },
              },
            },
          })
        end,
        desc = "Audit Agent (Unstaged vs Staged)",
      },
    },
    after = function()
      require("snacks").setup({
        animate = { enabled = true },
        debug = { enabled = true },
        image = { enabled = false },
        keymap = { enabled = true },
        lazygit = { enabled = true },
        bigfile = { enabled = true },
        dashboard = {
          -- Off for now. snacks merges its `defaults.sections` (which ends with
          -- { section = "startup" }) into whatever this table supplies, and that
          -- section hardcodes require("lazy.stats") — lazy.nvim's stats module,
          -- which nothing here provides. Supplying a shorter `sections` list does
          -- not remove it: list values merge by index.
          --
          -- Re-enable with { section = "startup", enabled = false } as the third
          -- entry once the surrounding `opts.config` nesting is understood. As
          -- written, `center`/`keys`/`sections` all sit under dashboard.opts.config,
          -- while snacks reads them as direct children of the dashboard config.
          enabled = false,
          opts = {
            config = {
              -- snacks' default sections end with { section = "startup" }, which
              -- calls require("lazy.stats") — lazy.nvim's stats module. Nothing
              -- here provides it, so the section errors on every UIEnter.
              sections = {
                { section = "header" },
                { section = "keys", gap = 1, padding = 1 },
              },
              center = {
                {
                  action = function()
                    require("snacks").picker.files()
                  end,
                  desc = " Find File",
                  icon = " ",
                  key = "f",
                },
                {
                  action = "ene | startinsert",
                  desc = " New File",
                  icon = " ",
                  key = "n",
                },
                {
                  action = function()
                    require("snacks").picker.recent()
                  end,
                  desc = " Recent Files",
                  icon = " ",
                  key = "r",
                },
                {
                  action = function()
                    require("snacks").picker.grep()
                  end,
                  desc = " Find Text",
                  icon = " ",
                  key = "g",
                },
                {
                  action = function()
                    require("snacks").picker.config_files()
                  end,
                  desc = " Config",
                  icon = " ",
                  key = "c",
                },
                {
                  action = function()
                    require("pick-resession").pick()
                  end,
                  desc = " Restore Session",
                  icon = " ",
                  key = "s",
                },
                {
                  action = function()
                    vim.api.nvim_input("<cmd>qa<cr>")
                  end,
                  desc = " Quit",
                  icon = " ",
                  key = "q",
                },
              },
            },
          },
        },
        explorer = {
          enabled = true,
          replace_netrw = true,

          layout = {
            layout = {
              position = "left",
              width = 30,
            },
          },

          keys = {
            -- Edit Actions (The Oil way)
            ["cw"] = "rename",
            ["dd"] = "delete",
            ["yy"] = "copy",
            ["p"] = "paste",
            ["o"] = "add",

            -- Navigation
            ["<CR>"] = "edit",
            ["l"] = "edit",
            ["h"] = "close",
            ["<Esc>"] = "close",
          },
        },
        indent = { enabled = true },
        input = { enabled = true },
        picker = {
          enabled = true,
          grep = { follow = true },
          previewers = {
            max_size = 1024 * 1024, -- 1MB
            max_line_length = 500, -- max line length
            ft = "txt", ---@type string? filetype for highlighting. Use `nil` for auto detect
          },
        },
        notifier = { enabled = true },
        quickfile = { enabled = true },
        scope = { enabled = true },
        scroll = { enabled = true },
        statuscolumn = { enabled = true },
        words = { enabled = true },
      })
    end,
  },
}
