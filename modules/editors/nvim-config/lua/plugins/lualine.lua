return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"letieu/harpoon-lualine",
		{ "AndreM222/copilot-lualine" },
	},
	event = "VeryLazy",
	opts = function(_, opts)
		-- ========================================================================
		-- 1. THE WIDTH CALCULATOR ENGINE (Absolute Center Logic)
		-- ========================================================================
		local component_widths = { mode = 0, branch = 0, diff = 0, ft = 0, filename = 0 }

		-- Helper: Measures the visual width of a component (stripping colors)
		local function track_width(str, name)
			-- Remove Lualine highlight codes (e.g., %#LualineMode#) to get real text length
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
		-- 2. THEME (group names, defined in lua/config/theme.lua)
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
		opts.options.theme = theme

		-- 3. GLOBAL SETTINGS
		opts.options.globalstatus = true
		opts.options.disabled_filetypes = { statusline = { "dashboard", "alpha", "starter" } }
		opts.options.section_separators = { left = "", right = "" }
		opts.options.component_separators = { left = "", right = "" }

		-- ========================================================================
		-- 4. SECTIONS CONFIGURATION (With Width Tracking)
		-- ========================================================================

		-- LEFT (Mode) - Tracked
		opts.sections.lualine_a = {
			{
				"mode",
				separator = { left = "", right = "" },
				padding = { left = 1, right = 0 },
				fmt = function(str)
					return track_width(str, "mode")
				end,
			},
		}

		-- LEFT (Branch/Diff) - Tracked
		opts.sections.lualine_b = {
			{
				"b:gitsigns_head",
				icon = "",
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
		}

		-- CENTER STRATEGY:
		-- [Filetype][Filename] -> [CALCULATED SPACER] -> [Tabs][Harpoon] -> [Flexible Spacer]
		opts.sections.lualine_c = {
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
				symbols = { modified = "●", readonly = "", unnamed = "󱙄" },
				separator = { right = "" },
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

			-- 5. HARPOON (The Centerpiece)
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
		}

		-- RIGHT (Diagnostics, Copilot)
		opts.sections.lualine_x = {
			{
				"diagnostics",
				symbols = { error = " ", warn = " ", info = " ", hint = " " },
			},
			{ "copilot", padding = { left = 0, right = 0 }, show_colors = false, spinners = "circle_halves" },
			-- {
			-- 	padding = { left = 0, right = 1 },
			-- 	function()
			-- 		return "󱚥"
			-- 	end,
			-- 	color = function()
			-- 		local status = require("sidekick.status").get()
			-- 		if status then
			-- 			return status.kind == "Error" and "Base16Red"
			-- 				or status.busy and "Base16Orange"
			-- 				or "StatusLineBg"
			-- 		end
			-- 	end,
			-- 	cond = function()
			-- 		local status = require("sidekick.status")
			-- 		return status.get() ~= nil
			-- 	end,
			-- },
		}

		-- RIGHT (Tech Details)
		opts.sections.lualine_y = {
			{ "encoding", padding = { left = 0, right = 1 } },
			{ "fileformat", padding = { left = 0, right = 1 } },
		}

		-- RIGHT (Location)
		opts.sections.lualine_z = {
			{ "progress", separator = { left = "", right = "" }, padding = { left = 0, right = 0 } },
			{ "location", separator = { right = "" }, padding = { left = 1, right = 1 } },
		}

		opts.extensions = { "oil", "aerial", "man", "fzf", "lazy" }
	end,
}
