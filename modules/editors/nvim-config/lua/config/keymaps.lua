-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any itional keymaps here
-- recommended mappings
-- resizing splits
-- these keymaps will also accept a range,
-- for example `10<A-h>` will `resize_left` by `(10 * config.default_amount)`
vim.keymap.set("n", "<A-h>", require("smart-splits").resize_left)
vim.keymap.set("n", "<A-j>", require("smart-splits").resize_down)
vim.keymap.set("n", "<A-k>", require("smart-splits").resize_up)
vim.keymap.set("n", "<A-l>", require("smart-splits").resize_right)
-- moving between splits
vim.keymap.set("n", "<C-h>", require("smart-splits").move_cursor_left)
vim.keymap.set("n", "<C-j>", require("smart-splits").move_cursor_down)
vim.keymap.set("n", "<C-k>", require("smart-splits").move_cursor_up)
vim.keymap.set("n", "<C-l>", require("smart-splits").move_cursor_right)
vim.keymap.set("n", "<C-\\>", require("smart-splits").move_cursor_previous)
-- swapping buffers between windows
vim.keymap.set("n", "<leader><leader>h", require("smart-splits").swap_buf_left)
vim.keymap.set("n", "<leader><leader>j", require("smart-splits").swap_buf_down)
vim.keymap.set("n", "<leader><leader>k", require("smart-splits").swap_buf_up)
vim.keymap.set("n", "<leader><leader>l", require("smart-splits").swap_buf_right)

vim.keymap.set("n", "<leader>rr", ":IncRename ")
-- vim.keymap.set("n", "p", "=p", { desc = "Paste and indent" })
-- vim.keymap.set("n", "P", "=P", { desc = "Paste before and indent" })
vim.keymap.set("n", "<leader>ga", function()
	Snacks.picker.git_status({
		title = "Audit Agent Changes",
		tree = true,
		-- preview = "file",
		-- preview_args = { "-U10000" },
		on_show = function()
			vim.cmd.stopinsert() -- Ensure normal mode
		end,
		layout = { preset = "sidebar", preview = "main" },
		win = {
			input = {
				keys = {
					["<Tab>"] = { "git_stage", mode = { "n", "i" } },
				},
			},
			preview = {
				minimal = false,
				wo = {
					signcolumn = "yes",
					cursorline = true,
				},
			},
		},
	})
end, { desc = "Audit Agent (Unstaged vs Staged)" })
vim.keymap.set("n", "<leader>de", function()
	require("dap").set_exception_breakpoints({ "Warning", "Error", "Exception" })
end, { desc = "Stop on exceptions" })
vim.keymap.set("n", "ga", function()
	vim.lsp.buf.code_action()
end, { desc = "LSP Code Action" })
--
-- vim.keymap.set("n", "<leader>ai", function()
-- 	local right = vim.fn.system("wezterm cli get-pane-direction Right"):gsub("%s+", "")
--
-- 	if right ~= "" then
-- 		vim.fn.system("wezterm cli zoom-pane --toggle")
-- 		return
-- 	end
--
-- 	local cwd = vim.fn.getcwd()
-- 	local shell = os.getenv("SHELL") or "bash"
-- 	vim.fn.system(
-- 		string.format("wezterm cli split-pane --right --percent 50 --cwd '%s' -- %s -ic opencode", cwd, shell)
-- 	)
-- end, { desc = "Toggle OpenCode via WezTerm CLI" })
