-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- Centralize all swap, backup, and undo files
local state_dir = vim.fn.stdpath("state") .. "/"

-- Keep swap files in one place
vim.opt.swapfile = true
vim.opt.directory = "/tmp//"

-- Keep backup files in one place
vim.opt.backup = true
vim.opt.backupdir = state_dir .. "backup//"

-- Keep undo files in one place
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

-- Check if the current session is a remote WezTerm session based on the WezTerm executable
local function check_wezterm_remote_clipboard(callback)
	local wezterm_executable = vim.uv.os_getenv("WEZTERM_EXECUTABLE")

	if wezterm_executable and wezterm_executable:find("wezterm-mux-server", 1, true) then
		callback(true) -- Remote WezTerm session found
	else
		callback(false) -- No remote WezTerm session
	end
end

-- Schedule the setting after `UiEnter` because it can increase startup-time.
vim.schedule(function()
	vim.opt.clipboard:append("unnamedplus")

	-- Standard SSH session handling
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
