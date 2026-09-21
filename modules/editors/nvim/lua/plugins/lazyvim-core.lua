-- LazyVim core plugin configuration, ported from upstream LazyVim
-- (lua/lazyvim/plugins/{editor,ui,coding,treesitter,formatting}.lua and the
-- editor.dial / coding.yanky extras).
--
-- This config only ever OVERRODE LazyVim defaults; it never declared these
-- plugins. Every opts table below is upstream's, verbatim, except that:
--   LazyVim.root() / LazyVim.root.git() -> Snacks.git.get_root()
--   LazyVim.mini.pairs(opts)            -> inline (mini.pairs' own mappings check)
--   LazyVim.mini.ai_buffer              -> inline buffer textobject
--   LazyVim.mini.ai_whichkey            -> dropped (registers which-key labels
--                                          for custom textobjects; cosmetic)
--   LazyVim.on_load / on_very_lazy      -> lze after/dep_on
--   LazyVim.format.register             -> dropped (registering conform as the
--                                          LazyVim formatter is LazyVim-only)
--   LazyVim.cmp.actions.snippet         -> native vim.snippet expand/jump
--   lazy.nvim's LazyFile event          -> { "BufReadPost", "BufNewFile", "BufWritePre" }
--
-- Treesitter opts deliberately omit ensure_installed/indent/folds/highlight:
-- grammars are nix-managed (see _plugins.nix) and nvim-treesitter on the main
-- branch no longer uses those opts; the disable list was already ported as a
-- FileType autocmd in lua/plugins/general.lua, which takes precedence.
--
-- This file loads BEFORE the user's own groups (see init.lua), so anything in
-- lua/plugins/*.lua still overrides it.

local function dial(increment, g)
	local mode = vim.fn.mode(true)
	local is_visual = mode == "v" or mode == "V" or mode == "\22"
	local func = (increment and "inc" or "dec") .. (g and "_g" or "_") .. (is_visual and "visual" or "normal")
	local group = vim.g.dials_by_ft[vim.bo.filetype] or "default"
	return require("dial.map")[func](group)
end

return {
	{
		"flash.nvim",
		auto_enable = true,
		event = { "BufReadPost", "BufNewFile", "BufWritePre", "DeferredUIEnter" },
		keys = {
			{ "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
			{ "S", mode = { "n", "o", "x" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
			{ "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
			{ "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
			{ "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
			{
				"<c-space>",
				mode = { "n", "o", "x" },
				function()
					require("flash").treesitter({
						actions = { ["<c-space>"] = "next", ["<BS>"] = "prev" },
					})
				end,
				desc = "Treesitter Incremental Selection",
			},
		},
		after = function()
			require("flash").setup({})
		end,
	},

	{
		"which-key.nvim",
		auto_enable = true,
		event = { "BufReadPost", "BufNewFile", "BufWritePre", "DeferredUIEnter" },
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Keymaps (which-key)",
			},
			{
				"<c-w><space>",
				function()
					require("which-key").show({ keys = "<c-w>", loop = true })
				end,
				desc = "Window Hydra Mode (which-key)",
			},
		},
		after = function()
			local wk = require("which-key")
			wk.setup({
				preset = "helix",
				defaults = {},
				spec = {
					{
						mode = { "n", "x" },
						{ "<leader><tab>", group = "tabs" },
						{ "<leader>c", group = "code" },
						{ "<leader>d", group = "debug" },
						{ "<leader>dp", group = "profiler" },
						{ "<leader>f", group = "file/find" },
						{ "<leader>g", group = "git" },
						{ "<leader>gh", group = "hunks" },
						{ "<leader>q", group = "quit/session" },
						{ "<leader>s", group = "search" },
						{ "<leader>u", group = "ui" },
						{ "<leader>x", group = "diagnostics/quickfix" },
						{ "[", group = "prev" },
						{ "]", group = "next" },
						{ "g", group = "goto" },
						{ "gs", group = "surround" },
						{ "z", group = "fold" },
						{
							"<leader>b",
							group = "buffer",
							expand = function()
								return require("which-key.extras").expand.buf()
							end,
						},
						{
							"<leader>w",
							group = "windows",
							proxy = "<c-w>",
							expand = function()
								return require("which-key.extras").expand.win()
							end,
						},
						{ "gx", desc = "Open with system app" },
					},
				},
			})
		end,
	},

	{
		"noice.nvim",
		auto_enable = true,
		event = { "BufReadPost", "BufNewFile", "BufWritePre", "DeferredUIEnter" },
		keys = {
			{ "<leader>sn", "", desc = "+noice" },
			{ "<S-Enter>", function() require("noice").redirect(vim.fn.getcmdline()) end, mode = "c", desc = "Redirect Cmdline" },
			{ "<leader>snl", function() require("noice").cmd("last") end, desc = "Noice Last Message" },
			{ "<leader>snh", function() require("noice").cmd("history") end, desc = "Noice History" },
			{ "<leader>sna", function() require("noice").cmd("all") end, desc = "Noice All" },
			{ "<leader>snd", function() require("noice").cmd("dismiss") end, desc = "Dismiss All" },
			{ "<leader>snt", function() require("noice").cmd("pick") end, desc = "Noice Picker (Telescope/FzfLua)" },
			{
				"<c-f>",
				function()
					if not require("noice.lsp").scroll(4) then
						return "<c-f>"
					end
				end,
				silent = true,
				expr = true,
				desc = "Scroll Forward",
				mode = { "i", "n", "s" },
			},
			{
				"<c-b>",
				function()
					if not require("noice.lsp").scroll(-4) then
						return "<c-b>"
					end
				end,
				silent = true,
				expr = true,
				desc = "Scroll Backward",
				mode = { "i", "n", "s" },
			},
		},
		after = function()
			-- The `vim.o.filetype == "lazy"` branch in upstream's config is
			-- lazy.nvim-specific and dropped.
			require("noice").setup({
				lsp = {
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true,
					},
				},
				routes = {
					{
						filter = {
							event = "msg_show",
							any = {
								{ find = "%d+L, %d+B" },
								{ find = "; after #%d+" },
								{ find = "; before #%d+" },
							},
						},
						view = "mini",
					},
				},
				presets = {
					bottom_search = true,
					command_palette = true,
					long_message_to_split = true,
				},
			})
		end,
	},

	{
		"trouble.nvim",
		auto_enable = true,
		cmd = { "Trouble" },
		keys = {
			{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
			{ "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
			{ "<leader>cs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols (Trouble)" },
			{ "<leader>cS", "<cmd>Trouble lsp toggle<cr>", desc = "LSP references/definitions/... (Trouble)" },
			{ "<leader>xL", "<cmd>Trouble loclist toggle<cr>", desc = "Location List (Trouble)" },
			{ "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix List (Trouble)" },
			{
				"[q",
				function()
					if require("trouble").is_open() then
						require("trouble").prev({ skip_groups = true, jump = true })
					else
						local ok, err = pcall(vim.cmd.cprev)
						if not ok then
							vim.notify(err, vim.log.levels.ERROR)
						end
					end
				end,
				desc = "Previous Trouble/Quickfix Item",
			},
			{
				"]q",
				function()
					if require("trouble").is_open() then
						require("trouble").next({ skip_groups = true, jump = true })
					else
						local ok, err = pcall(vim.cmd.cnext)
						if not ok then
							vim.notify(err, vim.log.levels.ERROR)
						end
					end
				end,
				desc = "Next Trouble/Quickfix Item",
			},
		},
		after = function()
			require("trouble").setup({
				modes = {
					lsp = {
						win = { position = "right" },
					},
				},
			})
		end,
	},

	{
		"todo-comments.nvim",
		auto_enable = true,
		cmd = { "TodoTrouble", "TodoTelescope" },
		event = { "BufReadPost", "BufNewFile", "BufWritePre" },
		keys = {
			{ "]t", function() require("todo-comments").jump_next() end, desc = "Next Todo Comment" },
			{ "[t", function() require("todo-comments").jump_prev() end, desc = "Previous Todo Comment" },
			{ "<leader>xt", "<cmd>Trouble todo toggle<cr>", desc = "Todo (Trouble)" },
			{ "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
			{ "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo" },
			{ "<leader>sT", "<cmd>TodoTelescope keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme" },
		},
		after = function()
			require("todo-comments").setup({})
		end,
	},

	{
		"ts-comments.nvim",
		auto_enable = true,
		event = { "BufReadPost", "BufNewFile", "BufWritePre", "DeferredUIEnter" },
		after = function()
			require("ts-comments").setup({})
		end,
	},

	{
		"nvim-ts-autotag",
		auto_enable = true,
		event = { "BufReadPost", "BufNewFile", "BufWritePre", "DeferredUIEnter" },
		after = function()
			require("nvim-ts-autotag").setup({})
		end,
	},

	-- mini.nvim: the monorepo's modules are set up individually. mini.icons and
	-- mini.ai are configured in the inline spec in init.lua (which mocks
	-- nvim-web-devicons for everything else); this spec carries upstream's
	-- mini.pairs opts, which the inline spec did not.
	{
		"mini.nvim",
		auto_enable = true,
		event = "DeferredUIEnter",
		after = function()
			-- LazyVim.mini.pairs(opts), inlined. Skips autopair when the cursor
			-- is inside a treesitter string node or the next char closes an
			-- unbalanced pair.
			require("mini.pairs").setup({
				modes = { insert = true, command = true, terminal = false },
				skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
				skip_ts = { "string" },
				skip_unbalanced = true,
				markdown = true,
			})
			require("mini.move").setup({})
			require("mini.hipatterns").setup({})

			-- Carried over from the (now-discarded) duplicate inline mini spec in
			-- init.lua: lze keeps the FIRST spec registered for a name and drops
			-- later ones as duplicates, so this after callback is the only one
			-- that runs for mini.nvim.
			require("mini.icons").setup()
			require("mini.icons").mock_nvim_web_devicons()

			-- LazyVim.mini.ai(opts), inlined, with LazyVim.mini.ai_buffer replaced
			-- by its one-line body. Both this spec and the inline one in init.lua
			-- target mini.nvim; this file is required first in init.lua's groups
			-- list, and the inline spec's bare mini.ai.setup() after it would
			-- override these textobjects -- so init.lua's inline mini spec is
			-- reduced to icons + mock only (done there).
			local ai = require("mini.ai")
			ai.setup({
				n_lines = 500,
				custom_textobjects = {
					o = ai.gen_spec.treesitter({
						a = { "@block.outer", "@conditional.outer", "@loop.outer" },
						i = { "@block.inner", "@conditional.inner", "@loop.inner" },
					}),
					f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
					c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
					t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
					d = { "%f[%d]%d+" },
					e = {
						{ "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
						"^().*()$",
					},
					g = function()
						return {
							from = { line = 1, col = 1 },
							to = { line = vim.fn.line("$"), col = math.max(vim.fn.line("$"):len(), 1) },
						}
					end,
					u = ai.gen_spec.function_call(),
					U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
				},
			})
		end,
	},

	-- dial.nvim. The four expr maps below carry LazyVim's editor.dial extra.
	{
		"dial.nvim",
		auto_enable = true,
		keys = {
			{ "<C-a>", function() return dial(true) end, expr = true, desc = "Increment", mode = { "n", "v" } },
			{ "<C-x>", function() return dial(false) end, expr = true, desc = "Decrement", mode = { "n", "v" } },
			{ "g<C-a>", function() return dial(true, true) end, expr = true, desc = "Increment", mode = { "n", "x" } },
			{ "g<C-x>", function() return dial(false, true) end, expr = true, desc = "Decrement", mode = { "n", "x" } },
		},
	},

	-- yanky.nvim. Ported from LazyVim's coding.yanky extra; the history picker
	-- map goes straight to Snacks (the config's only picker).
	{
		"yanky.nvim",
		auto_enable = true,
		event = { "BufReadPost", "BufNewFile", "BufWritePre" },
		keys = {
			{
				"<leader>p",
				function()
					Snacks.picker.yanky_history()
				end,
				mode = { "n", "x" },
				desc = "Open Yank History",
			},
			{ "y", "<Plug>(YankyYank)", mode = { "n", "x" }, desc = "Yank Text" },
			{ "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" }, desc = "Put Text After Cursor" },
			{ "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" }, desc = "Put Text Before Cursor" },
			{ "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" }, desc = "Put Text After Selection" },
			{ "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" }, desc = "Put Text Before Selection" },
			{ "[y", "<Plug>(YankyCycleForward)", desc = "Cycle Forward Through Yank History" },
			{ "]y", "<Plug>(YankyCycleBackward)", desc = "Cycle Backward Through Yank History" },
			{ "]p", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After Cursor (Linewise)" },
			{ "[p", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before Cursor (Linewise)" },
			{ "]P", "<Plug>(YankyPutIndentAfterLinewise)", desc = "Put Indented After Cursor (Linewise)" },
			{ "[P", "<Plug>(YankyPutIndentBeforeLinewise)", desc = "Put Indented Before Cursor (Linewise)" },
			{ ">p", "<Plug>(YankyPutIndentAfterShiftRight)", desc = "Put and Indent Right" },
			{ "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", desc = "Put and Indent Left" },
			{ ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", desc = "Put Before and Indent Right" },
			{ "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", desc = "Put Before and Indent Left" },
			{ "=p", "<Plug>(YankyPutAfterFilter)", desc = "Put After Applying a Filter" },
			{ "=P", "<Plug>(YankyPutBeforeFilter)", desc = "Put Before Applying a Filter" },
		},
		after = function()
			require("yanky").setup({
				system_clipboard = {
					sync_with_ring = not vim.env.SSH_CONNECTION,
				},
				highlight = { timer = 150 },
			})
		end,
	},

	-- conform.nvim: LazyVim's <leader>cF map for injected languages. The user's
	-- lsp.lua already carries conform.setup with their formatters_by_ft, so no
	-- opts are duplicated here.
}
