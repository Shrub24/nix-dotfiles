-- Rust support, from LazyVim's lang.rust extra: rustaceanvim owns the LSP, so
-- rust_analyzer is deliberately not enabled in lsp.lua.
return {
	{
		"crates.nvim",
		auto_enable = true,
		event = { "BufReadPre", "BufNewFile" },
		after = function()
			require("crates").setup({
				completion = { crates = { enabled = true } },
				lsp = { enabled = true, actions = true, completion = true, hover = true },
			})
		end,
	},
	{
		"rustaceanvim",
		auto_enable = true,
		event = { "BufReadPre", "BufNewFile" },
		after = function()
			vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, {
				server = {
					on_attach = function(_, bufnr)
						vim.keymap.set("n", "<leader>cR", function()
							vim.cmd.RustLsp("codeAction")
						end, { desc = "Code Action", buffer = bufnr })
						vim.keymap.set("n", "<leader>dr", function()
							vim.cmd.RustLsp("debuggables")
						end, { desc = "Rust Debuggables", buffer = bufnr })
					end,
					default_settings = {
						["rust-analyzer"] = {
							cargo = {
								allFeatures = true,
								loadOutDirsFromCheck = true,
								buildScripts = { enable = true },
							},
							checkOnSave = true,
							diagnostics = { enable = true },
							procMacro = { enable = true },
							files = {
								exclude = {
									".direnv",
									".git",
									".jj",
									".github",
									".gitlab",
									"bin",
									"node_modules",
									"target",
									"venv",
									".venv",
								},
								watcher = "client",
							},
						},
					},
				},
			})
		end,
	},
}
