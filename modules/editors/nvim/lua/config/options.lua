-- Editor options. Ported from the LazyVim config; the only change is dropping
-- the header that referenced LazyVim's own defaults.

-- Centralize swap, backup and undo files.
local state_dir = vim.fn.stdpath("state") .. "/"

vim.opt.swapfile = true
vim.opt.directory = "/tmp//"

vim.opt.backup = true
vim.opt.backupdir = state_dir .. "backup//"

vim.opt.undofile = true
vim.opt.undodir = state_dir .. "undo//"

local dirs = { vim.opt.backupdir:get()[1], vim.opt.undodir:get()[1] }
for _, dir in pairs(dirs) do
	local clean_dir = dir:gsub("//$", "")
	if vim.fn.isdirectory(clean_dir) == 0 then
		vim.fn.mkdir(clean_dir, "p")
	end
end

vim.opt.scrolloff = 12

vim.g.maplocalleader = "\\"

local function set_osc52_clipboard()
	local function my_paste()
		local content = vim.fn.getreg('"')
		return vim.split(content, "\n")
	end

	vim.g.clipboard = {
		name = "OSC 52",
		copy = {
			["+"] = require("vim.ui.clipboard.osc52").copy("+"),
			["*"] = require("vim.ui.clipboard.osc52").copy("*"),
		},
		paste = {
			["+"] = my_paste,
			["*"] = my_paste,
		},
	}
end

-- Remote WezTerm sessions cannot use the local clipboard.
local function check_wezterm_remote_clipboard(callback)
	local wezterm_executable = vim.uv.os_getenv("WEZTERM_EXECUTABLE")

	if wezterm_executable and wezterm_executable:find("wezterm-mux-server", 1, true) then
		callback(true)
	else
		callback(false)
	end
end

-- Scheduled after `UiEnter` because it can increase startup time.
vim.schedule(function()
	vim.opt.clipboard:append("unnamedplus")

	if vim.uv.os_getenv("SSH_CLIENT") ~= nil or vim.uv.os_getenv("SSH_TTY") ~= nil then
		set_osc52_clipboard()
	else
		check_wezterm_remote_clipboard(function(is_remote_wezterm)
			if is_remote_wezterm then
				set_osc52_clipboard()
			end
		end)
	end
end)
