-- Increment 1: prove the plumbing before porting behaviour.
--   startup plugins resolve, lze drives activation, the nix -> lua info channel
--   works, and treesitter + lsp binaries come from nix with no installer.
vim.loader.enable()

do
  -- _G.nixInfo is the nix -> lua channel. Under nix it reads values the wrapper
  -- baked in; outside nix the fallback returns the supplied default.
  local ok
  ok, _G.nixInfo = pcall(require, vim.g.nix_info_plugin_name)
  if not ok then
    package.loaded[vim.g.nix_info_plugin_name] = setmetatable({}, {
      __call = function(_, default)
        return default
      end,
    })
    _G.nixInfo = require(vim.g.nix_info_plugin_name)
  end
  nixInfo.isNix = vim.g.nix_info_plugin_name ~= nil

  ---@module 'lzextras'
  ---@type lzextras | lze
  nixInfo.lze = setmetatable(require("lze"), getmetatable(require("lzextras")))

  function nixInfo.get_nix_plugin_path(name)
    return nixInfo(nil, "plugins", "lazy", name) or nixInfo(nil, "plugins", "start", name)
  end
end

-- `auto_enable` drops a spec when nix did not install it, so the same Lua can
-- run outside nix without erroring.
nixInfo.lze.register_handlers {
  {
    spec_field = "auto_enable",
    set_lazy = false,
    modify = function(plugin)
      if not vim.g.nix_info_plugin_name then
        return plugin
      end
      local enabled = plugin.auto_enable
      if type(enabled) == "table" then
        for _, name in pairs(enabled) do
          if not nixInfo.get_nix_plugin_path(name) then
            plugin.enabled = false
            return plugin
          end
        end
      elseif type(enabled) == "string" then
        if not nixInfo.get_nix_plugin_path(enabled) then
          plugin.enabled = false
        end
      elseif enabled == true and not nixInfo.get_nix_plugin_path(plugin.name) then
        plugin.enabled = false
      end
      return plugin
    end,
  },
  {
    spec_field = "for_cat",
    set_lazy = false,
    modify = function(plugin)
      if vim.g.nix_info_plugin_name and type(plugin.for_cat) == "string" then
        plugin.enabled = nixInfo(false, "settings", "cats", plugin.for_cat)
      end
      return plugin
    end,
  },
}

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- LazyVim's core options first; config.options overrides.
require("config.options-lazyvim")
require("config.options")
require("config.keymaps-core") -- LazyVim defaults; own maps override
require("config.keymaps")
require("config.autocmds")
-- Opt-in capture; see lua/config/errorlog.lua. No-op without $NVIM_ERRORLOG.
require("config.errorlog")

local inline_specs = {
  -- mini.nvim is configured entirely in lua/plugins/lazyvim-core.lua (icons,
  -- mock, ai, pairs, move, hipatterns). lze keeps the first spec per name, so
  -- a second inline spec here would be silently discarded.
{
    -- Started at load because blink's <Tab> chain requires it directly; the old
    -- spec had `opts` with no lazy trigger, which lazy.nvim also started eagerly.
    "sidekick.nvim",
    auto_enable = true,
    after = function()
      require("sidekick").setup({
        cli = {
          watch = true,
          -- ai.lua disabled only the tmux mux backend.
          mux = { backend = "tmux", enabled = false },
        },
      })
    end,
  },
  {
    -- LazyVim's editor.inc-rename extra loaded this; `cmd` keeps the :IncRename
    -- command working without starting the plugin at load.
    "inc-rename.nvim",
    auto_enable = true,
    cmd = { "IncRename" },
    after = function()
      require("inc_rename").setup()
    end,
  },
  {
    "nvim-dap",
    auto_enable = true,
    keys = {
      {
        "<leader>de",
        function()
          require("dap").set_exception_breakpoints({ "Warning", "Error", "Exception" })
        end,
        desc = "Stop on exceptions",
      },
    },
  },
  -- blink.cmp requires these at completion time, not at setup time, so each is
  -- registered with lze's on_require: the plugin loads the moment blink calls
  -- require("<module>"). Without it, lze reports "no plugin registered to load
  -- on require of X" the first time the source is triggered.
  -- noice requires nui.<submodule> at runtime, so nui needs the same treatment.
  { "nui.nvim", auto_enable = true, on_require = "nui", after = function() end },
  { "blink-copilot", auto_enable = true, on_require = "blink-copilot", after = function() end },
  { "blink-nerdfont.nvim", auto_enable = true, on_require = "blink-nerdfont", after = function() end },
  { "blink-cmp-git", auto_enable = true, on_require = "blink-cmp-git", after = function() end },
  { "blink-ripgrep.nvim", auto_enable = true, on_require = "blink-ripgrep", after = function() end },
  -- blink-copilot drives copilot.lua, likewise only required on use.
  { "copilot.lua", auto_enable = true, on_require = "copilot", after = function() end },
  -- Menu/icon providers pulled in by module name from blink and lualine.
  { "nvim-web-devicons", auto_enable = true, on_require = "nvim-web-devicons", after = function() end },
  { "colorful-menu.nvim", auto_enable = true, on_require = "colorful-menu", after = function() end },
  { "lspkind.nvim", auto_enable = true, on_require = "lspkind", after = function() end },
  {
    -- Ported from lua/plugins/blink.lua. The old spec listed its sources as
    -- `dependencies`; under nix they are separate specs in _plugins.nix and
    -- only the provider wiring lives here.
    "blink.cmp",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      require("blink.cmp").setup({
        completion = {
          ghost_text = { enabled = true },
          documentation = { auto_show = true, auto_show_delay_ms = 1500 },
          menu = {
            draw = {
              components = {
                kind_icon = {
                  text = function(ctx)
                    local icon = ctx.kind_icon
                    if ctx.source_name == "Path" then
                      local dev_icon, _ = require("nvim-web-devicons").get_icon(ctx.label)
                      if dev_icon then
                        icon = dev_icon
                      end
                    else
                      icon = (require("lspkind").symbol_map[ctx.kind] or "") ~= "" and require("lspkind").symbol_map[ctx.kind] or ""
                    end
                    return icon .. ctx.icon_gap
                  end,
                  highlight = function(ctx)
                    local hl = ctx.kind_hl
                    if ctx.source_name == "Path" then
                      local dev_icon, dev_hl = require("nvim-web-devicons").get_icon(ctx.label)
                      if dev_icon then
                        hl = dev_hl
                      end
                    end
                    return hl
                  end,
                },
                label = {
                  text = function(ctx)
                    return require("colorful-menu").blink_components_text(ctx)
                  end,
                  highlight = function(ctx)
                    return require("colorful-menu").blink_components_highlight(ctx)
                  end,
                },
              },
            },
          },
        },
        sources = {
          default = { "lsp", "path", "snippets", "buffer", "copilot", "nerdfont", "git", "ripgrep" },
          providers = {
            -- copilot-lua supplies ghost text; blink-copilot surfaces it here.
            copilot = {
              name = "copilot",
              module = "blink-copilot",
              score_offset = 100,
              async = true,
            },
            path = {
              score_offset = 2000,
              opts = {
                get_cwd = function()
                  return vim.fn.getcwd()
                end,
              },
            },
            nerdfont = {
              module = "blink-nerdfont",
              name = "Nerd Fonts",
              score_offset = 20,
              opts = { insert = true, trigger = "!" },
            },
            git = {
              module = "blink-cmp-git",
              name = "Git",
              score_offset = 0,
              enabled = function()
                return vim.tbl_contains({ "lazygit", "octo", "gitcommit", "markdown" }, vim.bo.filetype)
              end,
            },
            ripgrep = {
              module = "blink-ripgrep",
              name = "Ripgrep",
              score_offset = -5,
              opts = { prefix_min_len = 4, backend = "gitgrep-or-ripgrep" },
            },
          },
        },
        keymap = {
          preset = "super-tab",
          ["<CR>"] = { "accept", "fallback" },
          ["<Tab>"] = {
            function(cmp)
              if cmp.snippet_active() then
                return cmp.accept()
              else
                return cmp.select_and_accept()
              end
            end,
            "snippet_forward",
            function() -- sidekick next-edit-suggestion
              return require("sidekick").nes_jump_or_apply()
            end,
            "fallback",
          },
        },
      })
    end,
  },
}

-- The colourscheme is set last: colors/noctalia.lua needs base16-nvim on the
-- runtimepath, and that spec is in the startup set for exactly this reason.
vim.cmd.colorscheme("noctalia")

require("sops_nvim").setup()

-- Plugin specs live one file per group under lua/plugins/, mirroring the
-- original config's layout. Each returns a list of lze specs. This list grows as
-- each remaining lua/plugins/*.lua is ported.
local groups = {
  -- LazyVim's core plugin layer first; the user's own groups then override it.
  "plugins.lazyvim-core",
  "plugins.aerial",
  "plugins.appearance",
  "plugins.buffers",
  "plugins.dap",
  "plugins.files",
  "plugins.general",
  "plugins.git",
  "plugins.harpoon",
  "plugins.lsp",
  "plugins.lualine",
  "plugins.repl",
  "plugins.resession",
  "plugins.snacks",
}

local specs = inline_specs
for _, mod in ipairs(groups) do
  vim.list_extend(specs, require(mod))
end

nixInfo.lze.load(specs)
