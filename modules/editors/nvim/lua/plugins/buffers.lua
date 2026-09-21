-- Buffer line and per-tab buffer scoping. Ported from lua/plugins/buffers.lua.
--
-- scope.nvim is load-bearing for resession: its config declares
-- `extensions = { scope = {} }`. `config = true` in the original means the
-- plugin's own setup() runs with defaults.
local function bufferline_opts()
  return {
    options = {
      diagnostics = "nvim_lsp",
      diagnostics_indicator = function(count, level, _diagnostics_dict, context)
        if context.buffer:current() then
          return ""
        end
        local icon = level:match("error") and " " or " "
        return " " .. icon .. count
      end,
      get_element_icon = function(element)
        local icon, hl = require("nvim-web-devicons").get_icon_by_filetype(element.filetype, { default = false })
        return icon, hl
      end,
      show_buffer_close_icons = false,
      show_close_icon = false,
      groups = {
        items = {
          require("bufferline.groups").builtin.pinned:with({ icon = "" }),

          {
            name = "Tests",
            icon = "",
            -- Base16BgGreen, not the old RainbowBgGreen: the noctalia theme
            -- provides the Base16* groups.
            highlight = { link = "Base16BgGreen" },
            matcher = function(buf)
              local n = buf.name
              if not n then
                return false
              end
              return n:match("_spec") or n:match(".test") or n:match("/tests/")
            end,
            auto_close = true,
          },
          {
            name = "Docs",
            icon = "",
            matcher = function(buf)
              local n = buf.name
              if not n then
                return false
              end
              return n:match("%.md") or n:match("%.txt")
            end,
            auto_close = true,
          },
          {
            name = "Configs",
            icon = "",
            matcher = function(buf)
              local n = buf.name
              if not n then
                return false
              end
              return n:match("%.yml") or n:match("%.yaml") or n:match("%.json") or n:match("%.toml")
            end,
            auto_close = true,
          },
          {
            name = "Dependencies",
            icon = "",
            matcher = function(buf)
              local path = buf.path
              if not path then
                return false
              end
              return path:match("node_modules")
                or path:match("%.venv")
                or path:match("site%-packages")
                or path:match("target/")
                or path:match("vendor/")
                or path:match("/lib/")
            end,
            auto_close = true,
            priority = 2,
          },

          require("bufferline.groups").builtin.ungrouped,
        },
      },
    },
  }
end

return {
  {
    "scope.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      require("scope").setup()
    end,
  },
  {
    "bufferline.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      require("bufferline").setup(bufferline_opts())
    end,
  },
}
