-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
-- in nvim/lua/config/autocmds.lua
local softwrap_group = vim.api.nvim_create_augroup("SoftwrapBuffers", { clear = true })
local opencode_group = vim.api.nvim_create_augroup("OpenCodeOptimizations", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	group = softwrap_group,
	pattern = "kulala_ui",
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
	end,
})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.pdf" },
	callback = function()
		local file = vim.fn.expand("%:p")
		-- Use xdg-open to launch Zathura/imv natively and close the binary buffer in nvim
		vim.fn.jobstart({ "xdg-open", file }, { detach = true })
		vim.api.nvim_buf_delete(0, { force = true })
	end,
})

local snacks_reactive_group = vim.api.nvim_create_augroup("SnacksReactiveToggle", { clear = true })

-- Disable Reactive in snacks picker to avoid preview cursor jump issues
vim.api.nvim_create_autocmd("FileType", {
	group = snacks_reactive_group,
	pattern = "snacks_picker_input",
	callback = function(args)
		pcall(vim.cmd, "Reactive disable")

		vim.api.nvim_create_autocmd({ "BufLeave", "BufDelete" }, {
			buffer = args.buf,
			once = true,
			callback = function()
				pcall(vim.cmd, "Reactive enable")
			end,
		})
	end,
})
