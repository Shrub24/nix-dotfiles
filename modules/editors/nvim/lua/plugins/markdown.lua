return {
	{
		-- Dependency-free browser preview (markdown, html, asciidoc, svg) with KaTeX and Mermaid.
		"live-preview.nvim",
		cmd = { "LivePreview" },
		keys = {
			{
				"<leader>cp",
				"<cmd>LivePreview start<cr>",
				ft = { "markdown", "html", "asciidoc", "svg" },
				desc = "Live Preview (start)",
			},
		},
	},
	{
		-- Terminal preview in a float, tab or split; sets no maps of its own.
		"md-render.nvim",
		cmd = { "MdRender" },
		keys = {
			{ "<leader>mp", "<Plug>(md-render-preview)", ft = "markdown", desc = "Markdown preview (float)" },
			{ "<leader>mt", "<Plug>(md-render-preview-tab)", ft = "markdown", desc = "Markdown preview (tab)" },
			{ "<leader>mr", "<Plug>(md-render-toggle)", ft = "markdown", desc = "Markdown render (toggle in place)" },
		},
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
			-- The manager never forgets wiped buffers; a later config-cache miss then throws "Invalid buffer id".
			vim.api.nvim_create_autocmd("BufWipeout", {
				callback = function(ev)
					local buffers = require("render-markdown.core.manager").buffers
					for i = #buffers, 1, -1 do
						if buffers[i] == ev.buf then
							table.remove(buffers, i)
						end
					end
					require("render-markdown.state").cache[ev.buf] = nil
				end,
			})
			Snacks.toggle({
				name = "Render Markdown",
				get = require("render-markdown").get,
				set = require("render-markdown").set,
			}):map("<leader>um")
		end,
	},
}
