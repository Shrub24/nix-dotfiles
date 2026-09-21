return {
	{
		"mrjones2014/smart-splits.nvim",
		lazy = false,
		opts = {
			multiplexer_integration = "herdr",
		},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		opts = {
			disable = { "latex", "text", "opencode", "opencode-output", "fstab", "kdl" },
		},
	},
	{
		"Bekaboo/dropbar.nvim",
		opts = {
			bar = {
				enable = function(buf, win, _)
					buf = vim._resolve_bufnr(buf)
					if not vim.api.nvim_buf_is_valid(buf) or not vim.api.nvim_win_is_valid(win) then
						return false
					end

					if
						not vim.api.nvim_buf_is_valid(buf)
						or not vim.api.nvim_win_is_valid(win)
						or vim.fn.win_gettype(win) ~= ""
						or vim.wo[win].winbar ~= ""
						or vim.bo[buf].ft == "help"
						or vim.bo[buf].ft == "matlab"
					then
						return false
					end

					local stat = vim.uv.fs_stat(vim.api.nvim_buf_get_name(buf))
					if stat and stat.size > 1024 * 1024 then
						return false
					end

					return vim.bo[buf].ft == "markdown"
						or pcall(vim.treesitter.get_parser, buf)
						or not vim.tbl_isempty(vim.lsp.get_clients({
							bufnr = buf,
							method = "textDocument/documentSymbol",
						}))
				end,
			},
		},
	},
	{
		"pwntester/octo.nvim",
		opts = {
			picker = "snacks",
		},
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		dependencies = "nvim-treesitter/nvim-treesitter",
	},
	{
		-- Single module of the mini.nvim monorepo already used for mini.ai /
		-- mini.pairs / mini.icons. Mappings kept as nvim-surround's so muscle
		-- memory carries over; visual mode is `sa` rather than nvim-surround's `S`.
		"nvim-mini/mini.surround",
		event = "VeryLazy",
		opts = {
			mappings = {
				add = "ys",
				delete = "ds",
				replace = "cs",
				find = "gs",
				find_left = "gS",
				highlight = "",
				update_n_lines = "",
			},
		},
	},
	-- "karb94/neoscroll.nvim",
	{
		"stevearc/conform.nvim",
		opts = {
			formatters = {
				shfmt = {},
			},
		},
	},
	{
		-- Broader ]/[ set than unimpaired; LazyVim already owns most prefixes, so
		-- only the groups it does not bind are enabled. `hunk` stays off because
		-- git.lua binds ]h / [h to gitsigns.
		"nvim-mini/mini.bracketed",
		event = "VeryLazy",
		-- Defaults: no `h` group, so git.lua's ]h / [h (gitsigns hunks) are untouched.
		opts = {},
	},
	-- {
	-- 	"linux-cultist/venv-selector.nvim",
	-- 	dependencies = {
	-- 		"neovim/nvim-lspconfig",
	-- 		"folke/snacks.nvim",
	-- 	},
	-- 	opts = {
	-- 		options = {
	-- 			picker = "snacks",
	-- 		},
	-- 	},
	-- 	ft = "python",
	-- 	keys = {
	-- 		{ ",v", "<cmd>VenvSelect<cr>" },
	-- 	},
	-- },
	{
		"kevinhwang91/nvim-hlslens",
		keys = {
			{
				"n",
				[[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
				desc = "Next Search Result",
			},
			{
				"N",
				[[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
				desc = "Prev Search Result",
			},
			{
				"*",
				[[*<Cmd>lua require('hlslens').start()<CR>]],
				desc = "Search Word Forward",
			},
			{
				"#",
				[[#<Cmd>lua require('hlslens').start()<CR>]],
				desc = "Search Word Backward",
			},
			{
				"g*",
				[[g*<Cmd>lua require('hlslens').start()<CR>]],
				desc = "Search Word Forward (Fuzzy)",
			},
			{
				"g#",
				[[g#<Cmd>lua require('hlslens').start()<CR>]],
				desc = "Search Word Backward (Fuzzy)",
			},
			{
				"<leader>L",
				"<cmd>nohlsearch<cr>",
				desc = "Clear Highlights",
			},
		},
	},
	-- {
	-- 	"amitds1997/remote-nvim.nvim",
	-- 	version = "*", -- Pin to GitHub releases
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim", -- For standard functions
	-- 		"MunifTanjim/nui.nvim", -- To build the plugin UI
	-- 		"nvim-telescope/telescope.nvim", -- For picking b/w different remote methods
	-- 	},
	-- 	config = true,
	-- },
	-- {
	-- 	"lewis6991/satellite.nvim",
	-- 	event = "VeryLazy",
	-- 	opts = {
	-- 		current_only = false,
	-- 		winblend = 0,
	-- 		width = 10,
	-- 		zindex = 40,
	-- 		excluded_filetypes = { "NvimTree", "neo-tree", "dashboard", "snacks_dashboard" },
	-- 		overlay = false,
	-- 		handlers = {
	-- 			cursor = {
	-- 				enabled = false,
	-- 			},
	-- 			search = { enable = true },
	-- 			diagnostic = { enable = true },
	-- 			gitsigns = { enable = true },
	-- 			marks = {
	-- 				enable = true,
	-- 				key = "",
	-- 			},
	-- 		},
	-- 	},
	-- },
	{
		"chentoast/marks.nvim",
		event = "VeryLazy",
		opts = {
			default_mappings = true,
		},
	},
	{
		"kevinhwang91/nvim-ufo",
	},
}
