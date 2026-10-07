-- Search/find/grep bindings from LazyVim's editor.snacks_picker extra.
-- Provenance + dropped maps: docs/keymaps-picker.md
local map = vim.keymap.set

-- Every binding is a picker source name; snacks is in the startup set.
local function pick(source, opts)
	return function()
		require("snacks").picker[source](opts)
	end
end

-- Find (also reached from <leader><space>)
map("n", "<leader>,", pick("buffers"), { desc = "Buffers" })
map("n", "<leader>/", pick("grep"), { desc = "Grep (Root Dir)" })
map("n", "<leader>:", pick("command_history"), { desc = "Command History" })
map("n", "<leader><space>", pick("files"), { desc = "Find Files (Root Dir)" })
map("n", "<leader>n", pick("notifications"), { desc = "Notification History" })
map("n", "<leader>fb", pick("buffers"), { desc = "Buffers" })
map("n", "<leader>fB", pick("buffers", { hidden = true, nofile = true }), { desc = "Buffers (all)" })
map("n", "<leader>fc", pick("files", { cwd = vim.fn.stdpath("config") }), { desc = "Find Config File" })
map("n", "<leader>ff", pick("files"), { desc = "Find Files (Root Dir)" })
map("n", "<leader>fF", pick("files", { root = false }), { desc = "Find Files (cwd)" })
map("n", "<leader>fg", pick("git_files"), { desc = "Find Files (git-files)" })
map("n", "<leader>fr", pick("recent"), { desc = "Recent" })
map("n", "<leader>fR", pick("recent", { filter = { cwd = true } }), { desc = "Recent (cwd)" })
map("n", "<leader>fp", pick("projects"), { desc = "Projects" })

-- Git
map("n", "<leader>gd", pick("git_diff"), { desc = "Git Diff (hunks)" })
map("n", "<leader>gD", pick("git_diff", { base = "origin", group = true }), { desc = "Git Diff (origin)" })
map("n", "<leader>gs", pick("git_status"), { desc = "Git Status" })
map("n", "<leader>gS", pick("git_stash"), { desc = "Git Stash" })
map("n", "<leader>gi", pick("gh_issue"), { desc = "GitHub Issues (open)" })
map("n", "<leader>gI", pick("gh_issue", { state = "all" }), { desc = "GitHub Issues (all)" })
map("n", "<leader>gp", pick("gh_pr"), { desc = "GitHub Pull Requests (open)" })
map("n", "<leader>gP", pick("gh_pr", { state = "all" }), { desc = "GitHub Pull Requests (all)" })

-- Grep
map("n", "<leader>sb", pick("lines"), { desc = "Buffer Lines" })
map("n", "<leader>sB", pick("grep_buffers"), { desc = "Grep Open Buffers" })
map("n", "<leader>sg", pick("grep"), { desc = "Grep (Root Dir)" })
map("n", "<leader>sG", pick("grep", { root = false }), { desc = "Grep (cwd)" })
map({ "n", "x" }, "<leader>sw", pick("grep_word"), { desc = "Visual selection or word (Root Dir)" })
map({ "n", "x" }, "<leader>sW", pick("grep_word", { root = false }), { desc = "Visual selection or word (cwd)" })

-- Search
map("n", '<leader>s"', pick("registers"), { desc = "Registers" })
map("n", "<leader>s/", pick("search_history"), { desc = "Search History" })
map("n", "<leader>sa", pick("autocmds"), { desc = "Autocmds" })
map("n", "<leader>sc", pick("command_history"), { desc = "Command History" })
map("n", "<leader>sC", pick("commands"), { desc = "Commands" })
map("n", "<leader>sd", pick("diagnostics"), { desc = "Diagnostics" })
map("n", "<leader>sD", pick("diagnostics_buffer"), { desc = "Buffer Diagnostics" })
map("n", "<leader>sh", pick("help"), { desc = "Help Pages" })
map("n", "<leader>sH", pick("highlights"), { desc = "Highlights" })
map("n", "<leader>si", pick("icons"), { desc = "Icons" })
map("n", "<leader>sj", pick("jumps"), { desc = "Jumps" })
map("n", "<leader>sk", pick("keymaps"), { desc = "Keymaps" })
map("n", "<leader>sl", pick("loclist"), { desc = "Location List" })
map("n", "<leader>sm", pick("marks"), { desc = "Marks" })
map("n", "<leader>sM", pick("man"), { desc = "Man Pages" })
map("n", "<leader>sR", pick("resume"), { desc = "Resume" })
map("n", "<leader>sq", pick("qflist"), { desc = "Quickfix List" })
map("n", "<leader>su", pick("undo"), { desc = "Undotree" })

-- UI
map("n", "<leader>uC", pick("colorschemes"), { desc = "Colorschemes" })
