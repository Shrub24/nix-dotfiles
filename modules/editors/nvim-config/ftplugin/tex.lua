return {
	"lervag/vimtex",
	lazy = false,
	init = function()
		vim.g.vimtex_view_enabled = 1
		vim.g.vimtex_view_method = "zathura_simple"
		vim.g.vimtex_view_geometry_locate = "0,0"
		vim.g.vimtex_compiler_method = "latexmk"
		vim.g.vimtex_quickfix_mode = 0
	end,
}
