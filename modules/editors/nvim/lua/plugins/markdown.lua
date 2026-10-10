return {
	{
		"markdown-preview.nvim",
		cmd = { "MarkdownPreview", "MarkdownPreviewStop", "MarkdownPreviewToggle" },
		keys = {
			{ "<leader>cp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview" },
		},
		after = function()
			vim.cmd("do FileType")
		end,
	},
	{
		"render-markdown.nvim",
		ft = { "markdown", "norg", "rmd", "org", "codecompanion" },
		after = function()
			require("render-markdown").setup({
				code = { sign = false, width = "block", right_pad = 1 },
				heading = { sign = false, icons = {} },
				checkbox = { enabled = false },
			})
			Snacks.toggle({
				name = "Render Markdown",
				get = require("render-markdown").get,
				set = require("render-markdown").set,
			}):map("<leader>um")
		end,
	},
}
