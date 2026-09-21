return {
	{
		"local/sops.nvim",
		dir = vim.fn.stdpath("config") .. "/lua/sops_nvim",
		lazy = false,
		config = function()
			require("sops_nvim").setup()
		end,
	},
}
