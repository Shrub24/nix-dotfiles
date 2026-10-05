-- resession needs scope.nvim (buffers.lua) for `extensions = { scope = {} }`, and
-- pick-resession for the pickers below.
local function resession_config()
  local resession = require("resession")

  resession.setup({
    autosave = { enabled = true, interval = 60, notify = true },
    buf_filter = function(bufnr)
      local buftype = vim.bo[bufnr].buftype
      if buftype == "help" then
        return true
      end
      if buftype ~= "" and buftype ~= "acwrite" then
        return false
      end
      if vim.api.nvim_buf_get_name(bufnr) == "" then
        return false
      end
      return true
    end,
    extensions = { scope = {} },
  })

  local project_dir = "session_projects"
  local auto_dir = "session_auto"

  -- == AUTOSAVE HISTORY ==
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      resession.save_tab(vim.fn.getcwd(), { dir = auto_dir, notify = false })
    end,
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      if vim.fn.argc(-1) == 0 or (vim.fn.argc(-1) == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1) then
        pcall(resession.load, vim.fn.getcwd(), { dir = project_dir, silence_errors = true })
      end
    end,
    nested = true,
  })

  local function create_finder(dir_name)
    return function()
      local sessions = {}
      local raw_list = resession.list({ dir = dir_name })

      for idx, path in ipairs(raw_list) do
        local icon = ""
        if path:match("Documents") then
          icon = "󰈙"
        end
        if path:match("config") or path:match("dotfiles") then
          icon = ""
        end
        if path:match("Projects") or path:match("projects") then
          icon = ""
        end

        local formatted = path:gsub(" __", ""):gsub("_", "/")
        local breadcrumb = formatted:gsub(vim.env.HOME, ""):gsub("mnt/LinuxData/", ""):gsub("^/", "")
        breadcrumb = breadcrumb:gsub("/", "")

        table.insert(sessions, {
          idx = idx,
          score = 0,
          -- the same resolved path feeds search, load and preview/icons
          text = formatted,
          value = formatted,
          file = formatted,

          -- Display: "  ~  projects  my-app"
          display_value = icon .. " " .. breadcrumb,
        })
      end
      return sessions
    end
  end

  -- == KEYBINDINGS ==

  vim.keymap.set("n", "<leader>qs", function()
    local cwd = vim.fn.getcwd()
    resession.save_tab(cwd, { dir = project_dir, notify = true })
    resession.load(cwd, { dir = project_dir, silence_errors = true })
    vim.notify("Saved Project: " .. cwd, vim.log.levels.INFO)
  end, { desc = "Save Project" })

  vim.keymap.set("n", "<leader>qp", function()
    require("pick-resession").pick({
      prompt_title = "Load Project",
      snacks_finder = create_finder(project_dir),
      dir = project_dir,
    })
  end, { desc = "Load Project" })

  vim.keymap.set("n", "<leader>ql", function()
    require("pick-resession").pick({
      prompt_title = "Load Recent",
      dir = auto_dir,
      snacks_finder = create_finder(auto_dir),
    })
  end, { desc = "Load Recent" })
end

return {
  {
    "resession.nvim",
    auto_enable = true,
    after = resession_config,
  },
  {
    "pick-resession.nvim",
    auto_enable = true,
    after = function()
      require("pick-resession").setup({
        layout = "ivy", -- "default", "dropdown", "ivy", "select", "vscode"
      })
    end,
  },
}
