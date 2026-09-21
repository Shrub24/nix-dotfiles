return {
	{
		"jpalardy/vim-slime",
		ft = { "python", "julia", "matlab" },
		init = function()
			vim.g.slime_target = "wezterm"
			vim.g.slime_bracketed_paste = 1
			vim.g.slime_default_config = {
				pane_direction = "right",
			}
			vim.g.slime_dont_ask_default = 1
		end,
		keys = {
			{ "<localleader>l", "<Plug>SlimeRegionSend", mode = "x", desc = "REPL Send Selection" },
			{ "<localleader>l", "<Plug>SlimeParagraphSend", mode = "n", desc = "REPL Send Paragraph" },
			{ "<localleader><CR>", ":%SlimeSend<CR>", mode = "n", desc = "REPL Run All" },
			{ "<localleader>S", "<Plug>SlimeConfig", mode = "n", desc = "Slime Config" },
		},
	},
	{
		"klafyvel/vim-slime-cells",
		dependencies = { "jpalardy/vim-slime" },
		ft = { "matlab" },
		keys = {
			{ "<localleader>c", "<Plug>SlimeCellsSendAndGoToNext", mode = "n", desc = "REPL Send Cell" },
			{ "<localleader>j", "<Plug>SlimeCellsNext", mode = "n", desc = "Next Slime Cell" },
			{ "<localleader>k", "<Plug>SlimeCellsPrev", mode = "n", desc = "Previous Slime Cell" },
		},
	},
}
