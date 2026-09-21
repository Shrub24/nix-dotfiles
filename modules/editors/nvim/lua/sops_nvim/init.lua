local M = {}

M.markers = {
	{ "%.ya?ml$", "^sops:", "yaml" },
	{ "%.json$", '^%s*"sops"', "json" },
	{ "%.ini$", "^%[sops%]", "dosini" },
	{ "%.env$", "sops_version=", "sh" },
	{ "%.dotenv$", "sops_version=", "sh" },
}

function M.detect(filename)
	for _, m in ipairs(M.markers) do
		if filename:lower():match(m[1]) then
			return m[2], m[3]
		end
	end
end

function M.relpath(root, filepath)
	if vim.startswith(filepath, root) then
		return filepath:sub(#root + 2)
	end
	return filepath
end

function M.run(args, stdin)
	local root = require("lazyvim.util").root.get()
	local cmd = ("cd %s && sops %s"):format(
		vim.fn.shellescape(root),
		table.concat(vim.tbl_map(vim.fn.shellescape, args), " ")
	)
	return vim.fn.system(cmd, stdin)
end

function M.setup()
	local group = vim.api.nvim_create_augroup("SopsNvim", { clear = true })
	local patterns = { "*.yaml", "*.yml", "*.json", "*.ini", "*.env", "*.dotenv" }

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = group,
		pattern = patterns,
		callback = function()
			local filename = vim.fn.expand("%:p")
			local marker, ft = M.detect(filename)
			if not marker then
				return
			end

			local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			for _, line in ipairs(lines) do
				if line:match(marker) then
					vim.b.sops_managed = true
					break
				end
			end
			if not vim.b.sops_managed then
				return
			end

			local result = M.run({ "-d", filename })
			if vim.v.shell_error ~= 0 then
				vim.notify("SOPS decrypt failed: " .. vim.trim(result), vim.log.levels.ERROR)
				return
			end

			local saved_undolevels = vim.bo.undolevels
			vim.bo.undolevels = -1
			vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(result, "\n"))
			vim.bo.undolevels = saved_undolevels
			vim.bo.modified = false
			vim.bo.filetype = ft

			vim.api.nvim_create_autocmd("BufWriteCmd", {
				group = group,
				buffer = 0,
				callback = function()
					local root = require("lazyvim.util").root.get()
					local relpath = M.relpath(root, filename)
					local content = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
					local result = M.run({ "-e", "--filename-override", relpath, "/dev/stdin" }, content)
					if vim.v.shell_error ~= 0 then
						vim.notify("SOPS encrypt failed: " .. vim.trim(result), vim.log.levels.ERROR)
						return
					end

					vim.fn.writefile(vim.split(result, "\n"), filename)
					vim.bo.modified = false
				end,
			})
		end,
	})
end

return M
