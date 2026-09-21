-- Keymaps that do not depend on an optional plugin. Maps whose callback needs
-- snacks or nvim-dap live in that plugin's lze spec (see init.lua), so they are
-- only created once the plugin is actually loaded.
--
-- `<leader>rr` uses inc-rename.nvim's `:IncRename` (live in-buffer preview of
-- the LSP rename). LazyVim supplied that command via its editor.inc-rename
-- extra; the plugin is now declared in _plugins.nix instead.
local map = vim.keymap.set
local splits = require("smart-splits")

-- Resizing splits. These accept a range: `10<A-h>` resizes by 10 steps.
map("n", "<A-h>", splits.resize_left)
map("n", "<A-j>", splits.resize_down)
map("n", "<A-k>", splits.resize_up)
map("n", "<A-l>", splits.resize_right)

-- Moving between splits, multiplexer-aware.
map("n", "<C-h>", splits.move_cursor_left)
map("n", "<C-j>", splits.move_cursor_down)
map("n", "<C-k>", splits.move_cursor_up)
map("n", "<C-l>", splits.move_cursor_right)
map("n", "<C-\\>", splits.move_cursor_previous)

-- Swapping buffers between windows.
map("n", "<leader><leader>h", splits.swap_buf_left)
map("n", "<leader><leader>j", splits.swap_buf_down)
map("n", "<leader><leader>k", splits.swap_buf_up)
map("n", "<leader><leader>l", splits.swap_buf_right)

map("n", "<leader>rr", ":IncRename ", { desc = "Rename symbol" })
map("n", "ga", vim.lsp.buf.code_action, { desc = "LSP code action" })

-- File explorer. snacks.explorer is a tree sidebar (oil stays for in-buffer
-- editing); it is configured in lua/plugins/snacks.lua.
vim.keymap.set("n", "<leader>e", function()
  require("snacks").explorer()
end, { desc = "Explorer (root dir)" })
vim.keymap.set("n", "<leader>E", function()
  require("snacks").explorer({ cwd = vim.fn.getcwd() })
end, { desc = "Explorer (cwd)" })
