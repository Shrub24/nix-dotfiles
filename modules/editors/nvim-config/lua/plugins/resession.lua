return {
	{
		"stevearc/resession.nvim",
		lazy = false,
		dependencies = {
			{ "tiagovla/scope.nvim", lazy = false, config = true },
			"scottmckendry/pick-resession.nvim",
		},
		opts = {
			-- Native Autosave (updates the currently open session file)
			autosave = { enabled = true, interval = 60, notify = true },
			-- Scope Filter
			buf_filter = function(bufnr)
				local buftype = vim.bo[bufnr].buftype
				if buftype == "help" then
					return true
				end
				if buftype ~= "" and buftype ~= "acwrite" then
					return false
				end
				if vim.api.nvim_buf_get_name(bufnr) == "" then
					return false
				end
				return true
			end,
			extensions = { scope = {} },
		},

		config = function(_, opts)
			local resession = require("resession")
			resession.setup(opts)

			local project_dir = "session_projects"
			local auto_dir = "session_auto"

			-- == AUTOSAVE HISTORY ==
			vim.api.nvim_create_autocmd("VimLeavePre", {
				callback = function()
					-- Always save directory state to 'session_auto' on exit
					resession.save_tab(vim.fn.getcwd(), { dir = auto_dir, notify = false })
				end,
			})

			vim.api.nvim_create_autocmd("VimEnter", {
				callback = function()
					if vim.fn.argc(-1) == 0 or (vim.fn.argc(-1) == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1) then
						pcall(resession.load, vim.fn.getcwd(), { dir = project_dir, silence_errors = true })
					end
				end,
				nested = true,
			})

			local function create_finder(dir_name)
				return function()
					local sessions = {}
					local raw_list = resession.list({ dir = dir_name })

					for idx, path in ipairs(raw_list) do
						local icon = "" -- Default Directory Icon
						if path:match("Documents") then
							icon = "󰈙"
						end
						if path:match("config") or path:match("dotfiles") then
							icon = ""
							-- icon = " "
						end
						if path:match("Projects") or path:match("projects") then
							icon = ""
						end

						local formatted = path:gsub(" __", ""):gsub("_", "/")
						local breadcrumb = formatted:gsub(vim.env.HOME, ""):gsub("mnt/LinuxData/", ""):gsub("^/", "")
						-- :gsub("^%s*(.-)%s*$", "%1")
						-- -- Replace slashes with Nerd Font Arrow
						breadcrumb = breadcrumb:gsub("/", "")

						table.insert(sessions, {
							idx = idx,
							score = 0,
							text = formatted, -- Keep original path for Fuzzy Searching
							value = formatted, -- Keep original path for Loading
							file = formatted, -- Enable File Preview/Icons in Snacks

							-- Display: "  ~  projects  my-app"
							display_value = icon .. " " .. breadcrumb,
						})
					end
					return sessions
				end
			end
			-- == KEYBINDINGS ==

			-- 1. SAVE PROJECT (Manual)
			-- We just use the CWD as the name. Simple.
			vim.keymap.set("n", "<leader>qs", function()
				local cwd = vim.fn.getcwd()
				resession.save_tab(cwd, { dir = project_dir, notify = true })
				resession.load(cwd, { dir = project_dir, silence_errors = true })
				vim.notify("Saved Project: " .. cwd, vim.log.levels.INFO)
			end, { desc = "Save Project" })

			-- 2. LOAD PROJECT (Curated List)
			-- Uses pick-resession standard logic.
			vim.keymap.set("n", "<leader>qp", function()
				require("pick-resession").pick({
					prompt_title = "Load Project",
					snacks_finder = create_finder(project_dir),
					dir = project_dir,
				})
			end, { desc = "Load Project" })

			-- 3. LOAD RECENT (History)
			vim.keymap.set("n", "<leader>ql", function()
				require("pick-resession").pick({
					prompt_title = "Load Recent",
					dir = auto_dir,
					snacks_finder = create_finder(auto_dir),
				})
			end, { desc = "Load Recent" })
		end,
	},
	{
		"scottmckendry/pick-resession.nvim",
		-- 2. Picker Configuration (UI, Layout, Icons)
		opts = {
			layout = "ivy", -- "default", "dropdown", "ivy", "select", "vscode"
			-- default_icon = {
			-- 	icon = " ",
			-- 	highlight = "directory",
			-- },
			-- Logic to handle your Shared Data Drive and Symlinks
			-- The plugin scans these in order; first match wins.
			-- path_icons = {
			-- 	-- Priority 1: Your Shared Data Projects (Symlinked)
			-- 	-- Even if the path is /mnt/LinuxData/Projects, this icon will appear
			-- 	{
			-- 		match = "/mnt/LinuxData/Projects",
			-- 		icon = " ", -- Github/Project Icon
			-- 		highlight = "projects",
			-- 	},
			-- 	{
			-- 		match = "/home/saurabhj/Projects",
			-- 		icon = " ",
			-- 		highlight = "projects",
			-- 	},
			-- 	-- Priority 2: Config
			-- 	{
			-- 		match = "/home/saurabhj/.config",
			-- 		icon = " ",
			-- 		highlight = "config",
			-- 	},
			-- 	-- Priority 3: Documents (Shared Drive)
			-- 	{
			-- 		match = "/mnt/LinuxData/Documents",
			-- 		icon = "󱔘", -- Doc icon
			-- 		highlight = "documents",
			-- 	},
			-- 	-- Priority 4: Home
			-- 	{
			-- 		match = "/home/saurabhj",
			-- 		icon = " ",
			-- 		highlight = "home",
			-- 	},
			-- },
		},
	},
}
