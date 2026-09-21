return {
	{
		-- Palette comes from the Noctalia template via matugen (lua/matugen.lua);
		-- the groups it does not cover live in lua/config/theme.lua, reached
		-- through colors/noctalia.lua.
		"RRethy/base16-nvim",
		lazy = false,
		priority = 1000,
	},
	{
		enabled = false,
		"rasulomaroff/reactive.nvim",
		event = "VeryLazy",
		opts = {
			configs = {
				noctalia = true,
			},
		},
		config = function()
			local reactive = require("reactive")
			local mode_map = {
				n = "Normal",
				i = "Insert",
				v = "Visual",
				V = "Visual",
				R = "Replace",
				c = "Command",
				t = "Terminal",
			}
			mode_map["\x16"] = "Visual"
			local preset_modes = {}
			for mode, prefix in pairs(mode_map) do
				preset_modes[mode] = {
					winhl = {
						Cursor = { link = prefix .. "ModeCursor" },
						CursorLineNr = { link = prefix .. "Mode" },
						CursorLine = { link = prefix .. "ModeLine" },
					},
				}
				if prefix == "Visual" then
					preset_modes[mode].winhl.Visual = { link = prefix .. "ModeCursor" }
				end
			end
			reactive.add_preset({
				name = "noctalia",
				modes = preset_modes,
			})
		end,
	},
	{
		"HiPhish/rainbow-delimiters.nvim",
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "noctalia",
		},
	},
	{
		lazy = true,
		enabled = false,
		"sphamba/smear-cursor.nvim",
		dir = "~/Projects/dev/custom/smear-cursor.nvim",
		opts = function(_, opts)
			opts.cursor_color = "Base16BgOrange"
			opts.cursor_color_insert_mode = "Base16BgGreen"
			opts.never_draw_over_target = true
			opts.hide_target_hack = true
			opts.gamma = 0.4
			opts.trailing_exponent = 3.0 -- 2.2     > 0
			opts.stiffness = 0.8 -- 0.6      [0, 1]
			opts.trailing_stiffness = 0.2 -- 0.45     [0, 1]
			opts.stiffness_insert_mode = 0.7 -- 0.5      [0, 1]
			opts.trailing_stiffness_insert_mode = 0.4 -- 0.5      [0, 1]
			opts.damping = 0.85 -- 0.85     [0, 1]
			opts.damping_insert_mode = 0.95 -- 0.9      [0, 1]
			opts.distance_stop_animating = 0.5 -- 0.1      > 0
		end,
	},
}
