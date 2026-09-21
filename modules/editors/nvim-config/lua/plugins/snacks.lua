return {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			animate = { enabled = true },
			debug = { enabled = true },
			image = { enabled = false },
			keymap = { enabled = true },
			lazygit = { enabled = true },
			bigfile = { enabled = true },
			dashboard = {
				enabled = true,
				opts = {
					config = {
						center = {
							{
								action = "lua LazyVim.pick()()",
								desc = " Find File",
								icon = " ",
								key = "f",
							},
							{
								action = "ene | startinsert",
								desc = " New File",
								icon = " ",
								key = "n",
							},
							{
								action = 'lua LazyVim.pick("oldfiles")()',
								desc = " Recent Files",
								icon = " ",
								key = "r",
							},
							{
								action = 'lua LazyVim.pick("live_grep")()',
								desc = " Find Text",
								icon = " ",
								key = "g",
							},
							{
								action = "lua LazyVim.pick.config_files()()",
								desc = " Config",
								icon = " ",
								key = "c",
							},
							{
								action = 'lua require("pick-resession").pick()',
								desc = " Restore Session",
								icon = " ",
								key = "s",
							},
							{
								action = "Lazy",
								desc = " Lazy",
								icon = "󰒲 ",
								key = "l",
							},
							{
								action = function()
									vim.api.nvim_input("<cmd>qa<cr>")
								end,
								desc = " Quit",
								icon = " ",
								key = "q",
							},
						},
					},
				},
			},
			explorer = {
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
					-- Strip the input window of ALL extra elements
					-- preview = false,
				},
				-- icons = {
				-- 	-- Remove the prompt prefix completely. This removes the left-side extmark
				-- 	-- which sometimes wraps around and affects EOL math in Neovim core.
				-- 	ui = {
				-- 		prompt = "",
				-- 		live = "", -- Remove live indicator
				-- 	},
				-- },
				-- sources = {
				-- 	explorer = { enabled = false },
				-- },
			},
			notifier = { enabled = true },
			quickfile = { enabled = true },
			scope = { enabled = true },
			scroll = { enabled = true },
			statuscolumn = { enabled = true },
			words = { enabled = true },
		},
	},
	-- {
	-- 	"folke/which-key.nvim",
	-- 	opts = {
	-- 		spec = {
	-- 			{ "<leader>a", group = "ai" },
	-- 			{ "<leader>aP", group = "permissions" },
	-- 			{ "<leader>ar", group = "revert" },
	-- 		},
	-- 	},
	-- },
}
