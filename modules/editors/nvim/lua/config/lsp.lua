-- LazyVim's LSP behaviour layer (maps, diagnostics, hints, folds) without LazyVim.
-- Port notes + deviations: docs/lsp.md

local function code_action(kind)
	vim.lsp.buf.code_action({
		apply = true,
		context = {
			only = { kind },
			diagnostics = {},
		},
	})
end

local function code_actions(filter)
	local kinds = {}
	local seen = {}
	for _, client in ipairs(vim.lsp.get_clients(filter)) do
		local static = vim.tbl_get(client, "server_capabilities", "codeActionProvider", "codeActionKinds")
		vim.list_extend(kinds, static or {})
		local regs = client.dynamic_capabilities:get("codeActionProvider", filter)
		for _, reg in ipairs(regs or {}) do
			vim.list_extend(kinds, vim.tbl_get(reg, "registerOptions", "codeActionKinds") or {})
		end
	end
	local ret = {}
	for _, kind in ipairs(kinds) do
		if not seen[kind] then
			seen[kind] = true
			ret[#ret + 1] = kind
		end
	end
	return ret
end

-- set_default: adopt unless locally overridden; LSP folds intentionally win
-- over the runtime ftplugins' treesitter foldexpr.
local defaults_set = {}
local function set_default(option, value)
	local local_value = vim.api.nvim_get_option_value(option, { scope = "local" })
	local global_value = vim.api.nvim_get_option_value(option, { scope = "global" })
	defaults_set[("%s=%s"):format(option, value)] = true
	if local_value ~= global_value and not defaults_set[("%s=%s"):format(option, local_value)] then
		local info = vim.api.nvim_get_option_info2(option, { scope = "local" })
		local scripts = vim.tbl_filter(function(script)
			return script.sid == info.last_set_sid
		end, vim.fn.getscriptinfo())
		local by_runtime = #scripts == 1 and vim.startswith(scripts[1].name, vim.fn.expand("$VIMRUNTIME"))
		if not by_runtime then
			return false
		end
	end
	vim.api.nvim_set_option_value(option, value, { scope = "local" })
	return true
end

-- LazyVim's servers["*"].keys (written positionally upstream). The picker variants for
-- gd/gr/gI/gy and ss/sS/gai/gao come from its editor.snacks_picker extra.
local keys = {
	{ lhs = "<leader>cl", rhs = function() Snacks.picker.lsp_config() end, desc = "Lsp Info" },
	{ lhs = "gd", rhs = function() Snacks.picker.lsp_definitions() end, desc = "Goto Definition", has = "definition" },
	{ lhs = "gr", rhs = function() Snacks.picker.lsp_references() end, desc = "References", nowait = true },
	{ lhs = "gI", rhs = function() Snacks.picker.lsp_implementations() end, desc = "Goto Implementation" },
	{ lhs = "gy", rhs = function() Snacks.picker.lsp_type_definitions() end, desc = "Goto T[y]pe Definition" },
	{ lhs = "gD", rhs = vim.lsp.buf.declaration, desc = "Goto Declaration" },
	{ lhs = "K", rhs = function() return vim.lsp.buf.hover() end, desc = "Hover" },
	{
		lhs = "gK",
		rhs = function() return vim.lsp.buf.signature_help() end,
		desc = "Signature Help",
		has = "signatureHelp",
	},
	{
		lhs = "<c-k>",
		rhs = function() return vim.lsp.buf.signature_help() end,
		mode = "i",
		desc = "Signature Help",
		has = "signatureHelp",
	},
	{
		lhs = "<leader>ca",
		rhs = vim.lsp.buf.code_action,
		desc = "Code Action",
		mode = { "n", "x" },
		has = "codeAction",
	},
	{
		lhs = "<leader>cc",
		rhs = vim.lsp.codelens.run,
		desc = "Run Codelens",
		mode = { "n", "x" },
		has = "codeLens",
	},
	{
		lhs = "<leader>cC",
		rhs = vim.lsp.codelens.refresh,
		desc = "Refresh & Display Codelens",
		mode = { "n" },
		has = "codeLens",
	},
	{
		lhs = "<leader>cR",
		rhs = function() Snacks.rename.rename_file() end,
		desc = "Rename File",
		mode = { "n" },
		has = { "workspace/didRenameFiles", "workspace/willRenameFiles" },
	},
	{ lhs = "<leader>cr", rhs = vim.lsp.buf.rename, desc = "Rename", has = "rename" },
	{ lhs = "<leader>cA", rhs = function() code_action("source") end, desc = "Source Action", has = "codeAction" },
	{
		lhs = "]]",
		rhs = function() Snacks.words.jump(vim.v.count1) end,
		has = "documentHighlight",
		desc = "Next Reference",
		enabled = function() return Snacks.words.is_enabled() end,
	},
	{
		lhs = "[[",
		rhs = function() Snacks.words.jump(-vim.v.count1) end,
		has = "documentHighlight",
		desc = "Prev Reference",
		enabled = function() return Snacks.words.is_enabled() end,
	},
	{
		lhs = "<a-n>",
		rhs = function() Snacks.words.jump(vim.v.count1, true) end,
		has = "documentHighlight",
		desc = "Next Reference",
		enabled = function() return Snacks.words.is_enabled() end,
	},
	{
		lhs = "<a-p>",
		rhs = function() Snacks.words.jump(-vim.v.count1, true) end,
		has = "documentHighlight",
		desc = "Prev Reference",
		enabled = function() return Snacks.words.is_enabled() end,
	},
	{
		lhs = "<leader>ss",
		rhs = function() Snacks.picker.lsp_symbols() end,
		desc = "LSP Symbols",
		has = "documentSymbol",
	},
	{
		lhs = "<leader>sS",
		rhs = function() Snacks.picker.lsp_workspace_symbols() end,
		desc = "LSP Workspace Symbols",
		has = "workspace/symbols",
	},
	{
		lhs = "gai",
		rhs = function() Snacks.picker.lsp_incoming_calls() end,
		desc = "Calls Incoming",
		has = "callHierarchy/incomingCalls",
	},
	{
		lhs = "gao",
		rhs = function() Snacks.picker.lsp_outgoing_calls() end,
		desc = "Calls Outgoing",
		has = "callHierarchy/outgoingCalls",
	},
	{
		lhs = "<leader>co",
		rhs = function() code_action("source.organizeImports") end,
		desc = "Organize Imports",
		has = "codeAction",
		enabled = function(buf)
			local actions = vim.tbl_filter(function(action)
				return action:find("^source%.organizeImports%.?$")
			end, code_actions({ bufnr = buf }))
			return #actions > 0
		end,
	},
}

-- Capabilities for all servers, with the keys above on the config so apply_keys()
-- and `:lua vim.lsp.config["*"].keys` share one source.
vim.lsp.config("*", {
	capabilities = {
		workspace = {
			fileOperations = {
				didRename = true,
				willRename = true,
			},
		},
	},
	keys = keys,
})

-- LazyVim's opts.diagnostics, with the default icons from lazyvim.config.icons.
vim.diagnostic.config({
	underline = true,
	update_in_insert = false,
	virtual_text = {
		spacing = 4,
		source = "if_many",
		prefix = "●",
	},
	severity_sort = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN] = " ",
			[vim.diagnostic.severity.HINT] = " ",
			[vim.diagnostic.severity.INFO] = " ",
		},
	},
})

local inlay_hints_exclude = { "vue" }

-- A `has` name resolves to an LSP method, as upstream did: "definition" ->
-- "textDocument/definition".
local function method_supported(buf, has)
	local methods = type(has) == "string" and { has } or has
	for _, method in ipairs(methods) do
		local name = method:find("/", 1, true) and method or ("textDocument/" .. method)
		if #vim.lsp.get_clients({ bufnr = buf, method = name }) > 0 then
			return true
		end
	end
	return false
end

local function key_enabled(key, buf)
	if key.enabled == nil then
		return true
	end
	if type(key.enabled) == "function" then
		return key.enabled(buf)
	end
	return key.enabled
end

local function apply_keys(buf)
	for _, key in ipairs(keys) do
		if key_enabled(key, buf) and (key.has == nil or method_supported(buf, key.has)) then
			vim.keymap.set(key.mode or "n", key.lhs, key.rhs, {
				buffer = buf,
				desc = key.desc,
				nowait = key.nowait,
			})
		end
	end
end

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("NvimConfigLsp", { clear = true }),
	callback = function(args)
		local buf = args.buf
		local client = vim.lsp.get_client_by_id(args.data.client_id)

		apply_keys(buf)

		if
			client
			and client:supports_method("textDocument/inlayHint")
			and vim.bo[buf].buftype == ""
			and not vim.tbl_contains(inlay_hints_exclude, vim.bo[buf].filetype)
		then
			vim.lsp.inlay_hint.enable(true, { bufnr = buf })
		end

		if client and client:supports_method("textDocument/foldingRange") then
			if set_default("foldmethod", "expr") then
				set_default("foldexpr", "v:lua.vim.lsp.foldexpr()")
			end
		end
	end,
})
