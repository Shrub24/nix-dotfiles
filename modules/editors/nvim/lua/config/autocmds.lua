local augroup = vim.api.nvim_create_augroup("NvimConfig", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- Hand image and PDF buffers to the desktop and close the buffer.
autocmd("BufEnter", {
	pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.pdf" },
	callback = function()
		local file = vim.fn.expand("%:p")
		vim.fn.jobstart({ "xdg-open", file }, { detach = true })
		vim.api.nvim_buf_delete(0, { force = true })
	end,
})

-- Re-read a buffer that changed on disk and has no local edits.
autocmd("FocusGained", {
	group = augroup,
	pattern = "*",
	command = "if mode() == 'n' && getcmdwintype() == '' | checktime | endif",
})

-- Restore the cursor to the last edited position.
autocmd("BufReadPost", {
	group = augroup,
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
			vim.api.nvim_win_set_cursor(0, mark)
		end
	end,
})

-- Trailing whitespace is visible, not silent.
vim.api.nvim_set_hl(0, "TrailingWhitespace", { link = "DiagnosticUnnecessary" })
vim.fn.matchadd("TrailingWhitespace", [[\s\+$]])
