return {
	{
		"stevearc/oil.nvim",
		dependencies = { { "nvim-mini/mini.icons", opts = {} } },
		keys = {
			{
				"<leader>W",
				function()
					require("oil").open(nil, { preview = {} })
				end,
				desc = "Open Oil",
			},
		},
		opts = {
			watch_for_changes = true,
			keymaps = {
				["H"] = { "actions.toggle_hidden", mode = "n" },
			},
			view_options = {
				show_hidden = true,
			},
		},
	},
	{
		"mikavilpas/yazi.nvim",
		enabled = false,
		version = "*",
		event = "VeryLazy",
		dependencies = {
			{ "nvim-lua/plenary.nvim", lazy = true },
		},
	},
}
