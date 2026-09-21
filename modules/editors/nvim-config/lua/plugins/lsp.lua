-- LSP servers are provided by Nix (modules/editors/lsp.nix); LazyVim resolves
-- them from PATH via vim.fn.executable(), so only per-server settings live here.
return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				basedpyright = {
					enabled = true,
					settings = {
						basedpyright = {
							analysis = {
								diagnosticMode = "workspace",
							},
						},
					},
				},
				ruff = {
					enabled = true,
					settings = {
						ruff = {
							diagnosticMode = "workspace",
						},
					},
				},
			},
		},
	},
	{
		"stevearc/conform.nvim",
		opts = {
			formatters_by_ft = {
				yaml = { "yamlfmt" },
				python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
			},
		},
	},
	{
		"ThePrimeagen/refactoring.nvim",
		dependencies = {
			"lewis6991/async.nvim",
		},
		lazy = false,
	},
}
