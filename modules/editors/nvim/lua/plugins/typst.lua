return {
	{
		-- nixpkgs patches in the tinymist and websocat store paths; no runtime download.
		"typst-preview.nvim",
		ft = "typst",
		cmd = { "TypstPreview", "TypstPreviewToggle", "TypstPreviewStop" },
		keys = {
			{ "<leader>cp", "<cmd>TypstPreviewToggle<cr>", ft = "typst", desc = "Typst Preview (browser)" },
		},
	},
}
