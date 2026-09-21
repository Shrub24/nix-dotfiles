-- Ported from lua/plugins/lualine.lua. The width-calculator engine, theme
-- mapping to the noctalia Base16* groups, and every section are the original
-- `opts` function verbatim.
--
-- The harpoon2 component needs harpoon (not yet in _plugins.nix); lualine
-- renders an empty section for a missing source rather than erroring, so the
-- component is kept and harpoon is recorded as pending in _keymap-parity.md.
--
-- Removed: the `extensions` entry "lazy" (no lazy.nvim anymore) and the
-- commented-out sidekick block (kept upstream in git history).
local component_widths = { mode = 0, branch = 0, diff = 0, ft = 0, filename = 0 }

-- Helper: Measures the visual width of a component (stripping colors)
local function track_width(str, name)
  -- Remove Lualine highlight codes (e.g. %#LualineMode#) to get real text length
  local text_only = str:gsub("%%#.-#", "")
  component_widths[name] = vim.fn.strdisplaywidth(text_only)
  return str
end

-- Helper: Calculates the exact spaces needed to reach the center
local function get_center_padding()
  local screen_width = vim.o.columns

  -- 1. Sum of everything to the left
  local left_width = (component_widths.mode or 0)
    + (component_widths.branch or 0)
    + (component_widths.diff or 0)
    + (component_widths.ft or 0)
    + (component_widths.filename or 0)

  local center_group_width = 25

  -- 3. The Math: (Screen/2) - Left_Stuff - (Center_Stuff/2)
  local padding = math.floor((screen_width / 2) - left_width - (center_group_width / 2))
  if padding < 0 then
    padding = 0
  end

  return string.rep(" ", padding)
end

local function diff_source()
  local gitsigns = vim.b.gitsigns_status_dict
  if gitsigns then
    return {
      added = gitsigns.added,
      modified = gitsigns.changed,
      removed = gitsigns.removed,
    }
  end
end

-- ========================================================================
-- 2. THEME (group names, defined in colors/noctalia.lua)
-- ========================================================================

local theme = {}
for _, mode in ipairs({ "insert", "normal", "visual", "command", "replace", "inactive", "terminal" }) do
  local chip = mode:gsub("^%l", string.upper) .. "ModeBg"
  theme[mode] = {
    a = chip,
    b = "Base16BgYellow",
    c = "StatusLineBg",
    x = "StatusLineBg",
    y = "Base16BgYellow",
    z = chip,
  }
end

local function lualine_opts()
  return {
    options = {
      theme = theme,
      globalstatus = true,
      disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } },
      section_separators = { left = "", right = "" },
      component_separators = { left = "", right = "" },
    },

    -- ======================================================================
    -- 4. SECTIONS CONFIGURATION (With Width Tracking)
    -- ======================================================================

    -- LEFT (Mode) - Tracked
    sections = {
      lualine_a = {
        {
          "mode",
          separator = { left = "", right = "" },
          padding = { left = 1, right = 0 },
          fmt = function(str)
            return track_width(str, "mode")
          end,
        },
      },

      -- LEFT (Branch/Diff) - Tracked
      lualine_b = {
        {
          "b:gitsigns_head",
          icon = "",
          fmt = function(str)
            return track_width(str, "branch")
          end,
        },
        {
          "diff",
          fmt = function(str)
            return track_width(str, "diff")
          end,
          source = diff_source,
        },
      },

      -- CENTER STRATEGY:
      -- [Filetype][Filename] -> [CALCULATED SPACER] -> [Tabs][Harpoon] -> [Flexible Spacer]
      lualine_c = {
        -- 1. Filetype (Tracked)
        {
          "filetype",
          icon_only = true,
          separator = "",
          padding = { left = 1, right = 0 },
          colored = false,
          icon = { align = "right" },
          fmt = function(str)
            return track_width(str, "ft")
          end,
        },
        -- 2. Filename (Tracked)
        {
          "filename",
          path = 1,
          symbols = { modified = "●", readonly = "", unnamed = "󱙄" },
          separator = { right = "" },
          fmt = function(str)
            local fixed_width = 30
            local formatted = str
            if #formatted > fixed_width then
              formatted = "..." .. string.sub(formatted, -(fixed_width - 3))
            end
            return track_width(formatted, "filename")
          end,
        },

        -- 3. THE MAGIC PADDER (Pushes Center Group to Absolute Center)
        {
          function()
            return get_center_padding()
          end,
          padding = 0,
          separator = "",
        },

        -- 5. HARPOON (The Centerpiece) — harpoon is not in the closure yet
        {
          "harpoon2",
          icon = "󰀱",
          indicators = { "󰲡", "󰲣", "󰲥", "󰲧", "󰲩", "󰲫", "󰲭", "󰲯", "󰲱" },
          active_indicators = { "󰲠", "󰲢", "󰲤", "󰲦", "󰲨", "󰲪", "󰲬", "󰲮", "󰲰" },
          color_active = "Base16Orange",
          no_harpoon = "",
        },

        -- 6. RIGHT FILLER (Pushes remaining components to far right)
        {
          function()
            return "%="
          end,
          separator = "",
        },
      },

      -- RIGHT (Diagnostics, Copilot)
      lualine_x = {
        {
          "diagnostics",
          symbols = { error = " ", warn = " ", info = " ", hint = " " },
        },
        { "copilot", padding = { left = 0, right = 0 }, show_colors = false, spinners = "circle_halves" },
      },

      -- RIGHT (Tech Details)
      lualine_y = {
        { "encoding", padding = { left = 0, right = 1 } },
        { "fileformat", padding = { left = 0, right = 1 } },
      },

      -- RIGHT (Location)
      lualine_z = {
        { "progress", separator = { left = "", right = "" }, padding = { left = 0, right = 0 } },
        { "location", separator = { right = "" }, padding = { left = 1, right = 1 } },
      },
    },

    extensions = { "oil", "aerial", "man", "fzf" },
  }
end

return {
  {
    "lualine.nvim",
    auto_enable = true,
    event = "DeferredUIEnter",
    after = function()
      require("lualine").setup(lualine_opts())
    end,
  },
}
