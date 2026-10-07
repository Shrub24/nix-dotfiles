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
          -- off because snacks merges `sections` by index, so its default
          -- trailing "startup" section (require("lazy.stats")) cannot be dropped.
          enabled = false,
          opts = {
            config = {
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
            max_size = 1024 * 1024,
            max_line_length = 500,
            ft = "txt",
          },
          win = {
            input = {
              keys = { ["<a-c>"] = { "toggle_cwd", mode = { "n", "i" } } },
            },
          },
          actions = {
            -- LazyVim's toggle_cwd, without LazyVim.root().
            toggle_cwd = function(p)
              local root = vim.fs.normalize(vim.fs.root(p.input.filter.current_buf or 0, { ".git" }) or vim.uv.cwd())
              local cwd = vim.fs.normalize(vim.uv.cwd())
              local current = p:cwd()
              p:set_cwd(current == root and cwd or root)
              p:find()
            end,
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
