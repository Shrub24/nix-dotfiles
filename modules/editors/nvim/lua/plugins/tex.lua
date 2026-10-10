-- vimtex, from LazyVim's lang.tex extra; the vim.g settings are the user's own,
-- carried over from the previous config's ftplugin/tex.lua (which was inert).
return {
	{
		"vimtex",
		auto_enable = true,
		event = { "BufReadPre", "BufNewFile", "DeferredUIEnter" },
		keys = {
			{ "<localLeader>l", "", desc = "+vimtex", ft = "tex" },
		},
		after = function()
			vim.g.vimtex_view_enabled = 1
			vim.g.vimtex_view_method = "zathura_simple"
			vim.g.vimtex_view_geometry_locate = "0,0"
			vim.g.vimtex_compiler_method = "latexmk"
			vim.g.vimtex_quickfix_mode = 0
			vim.g.vimtex_mappings_disable = { ["n"] = { "K" } }
			vim.g.vimtex_quickfix_method = vim.fn.executable("pplatex") == 1 and "pplatex" or "latexlog"
		end,
	},
}
