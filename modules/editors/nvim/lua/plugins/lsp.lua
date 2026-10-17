-- Servers are enabled with `vim.lsp.enable`, gated on `vim.fn.executable()` where optional.
return {
	{
		"nvim-lspconfig",
		auto_enable = true,
		event = "DeferredUIEnter",
		after = function()
			vim.lsp.enable("basedpyright")
			vim.lsp.enable("ruff")
			vim.lsp.enable("lua_ls")
			vim.lsp.enable("bashls")
			-- from LazyVim's lang.json/yaml/markdown/tex/go/helm and linting.eslint extras.
			vim.lsp.enable("jsonls")
			vim.lsp.enable("yamlls")
			vim.lsp.enable("marksman")
			vim.lsp.enable("texlab")
			vim.lsp.enable("gopls")
			vim.lsp.enable("helm_ls")
			vim.lsp.enable("eslint")
			vim.lsp.enable("ast_grep")
			vim.lsp.enable("vtsls")
			vim.lsp.enable("typos_lsp")
			-- nil/taplo/docker: binaries already on the wrapper's PATH.
			vim.lsp.enable("nil_ls")
			vim.lsp.enable("taplo")
			vim.lsp.enable("dockerls")
			vim.lsp.enable("docker_compose_language_service")
			-- `just` is absent: lspconfig's server needs `just-lsp` on PATH. Enable it
			-- here once the package is added.
			-- copilot.lua owns the copilot client; never vim.lsp.enable("copilot") too,
			-- since copilot.lua stops any second one (exit 143).
		end,
	},
	{
		"conform.nvim",
		auto_enable = true,
		event = "DeferredUIEnter",
		keys = {
			{
				"<leader>cF",
				function()
					require("conform").format({ formatters = { "injected" }, timeout_ms = 3000 })
				end,
				mode = { "n", "x" },
				desc = "Format Injected Langs",
			},
		},
		after = function()
			local prettier_supported = {
				"css",
				"graphql",
				"handlebars",
				"html",
				"javascript",
				"javascriptreact",
				"json",
				"jsonc",
				"less",
				"markdown",
				"markdown.mdx",
				"scss",
				"typescript",
				"typescriptreact",
				"vue",
				"yaml",
			}

			local function has_parser(ctx)
				local ft = vim.bo[ctx.buf].filetype
				if vim.tbl_contains(prettier_supported, ft) then
					return true
				end
				local ret = vim.fn.system({ "prettier", "--file-info", ctx.filename })
				local ok, parser = pcall(function()
					return vim.fn.json_decode(ret).inferredParser
				end)
				return ok and parser and parser ~= vim.NIL
			end

			local function has_config(ctx)
				vim.fn.system({ "prettier", "--find-config-path", ctx.filename })
				return vim.v.shell_error == 0
			end

			local formatters_by_ft = {
				lua = { "stylua" },
				fish = { "fish_indent" },
				sh = { "shfmt" },
				yaml = { "yamlfmt" },
				python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
				markdown = { "prettier", "markdownlint-cli2", "markdown-toc" },
				["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
			}
			for _, ft in ipairs(prettier_supported) do
				local list = formatters_by_ft[ft] or {}
				if not vim.tbl_contains(list, "prettier") then
					table.insert(list, "prettier")
				end
				formatters_by_ft[ft] = list
			end

			require("conform").setup({
				formatters = {
					injected = { options = { ignore_errors = true } },
					prettier = {
						condition = function(_, ctx)
							return has_parser(ctx) and (vim.g.lazyvim_prettier_needs_config ~= true or has_config(ctx))
						end,
					},
					["markdown-toc"] = {
						condition = function(_, ctx)
							for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
								if line:find("<!%-%- toc %-%->") then
									return true
								end
							end
						end,
					},
					["markdownlint-cli2"] = {
						condition = function(_, ctx)
							local diag = vim.tbl_filter(function(d)
								return d.source == "markdownlint"
							end, vim.diagnostic.get(ctx.buf))
							return #diag > 0
						end,
					},
				},
				formatters_by_ft = formatters_by_ft,
				default_format_opts = { timeout_ms = 3000, async = false, quiet = false, lsp_format = "fallback" },
			})

			vim.api.nvim_create_autocmd("BufWritePre", {
				group = vim.api.nvim_create_augroup("AutoFormat", { clear = true }),
				callback = function(event)
					local enabled = vim.b[event.buf].autoformat
					if enabled == nil then
						enabled = vim.g.autoformat == nil or vim.g.autoformat
					end
					if enabled then
						require("conform").format({ bufnr = event.buf })
					end
				end,
			})
		end,
	},
}
