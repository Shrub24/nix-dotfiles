-- Reproduces the setup from LazyVim's editor.harpoon2 extra.
return {
	{
		"harpoon2",
		auto_enable = true,
		event = "DeferredUIEnter",
		keys = (function()
			local keys = {
				{
					"<leader>H",
					function()
						require("harpoon"):list():add()
					end,
					desc = "Harpoon File",
				},
				{
					"<leader>h",
					function()
						local harpoon = require("harpoon")
						harpoon.ui:toggle_quick_menu(harpoon:list())
					end,
					desc = "Harpoon Quick Menu",
				},
			}
			for i = 1, 9 do
				table.insert(keys, {
					"<leader>" .. i,
					function()
						require("harpoon"):list():select(i)
					end,
					desc = "Harpoon to File " .. i,
				})
			end
			return keys
		end)(),
		after = function()
			require("harpoon"):setup({
				menu = { width = vim.o.columns - 4 },
				settings = { save_on_toggle = true },
			})
		end,
	},
	{
		-- lualine's centre component: a component, not a plugin, so no setup().
		"harpoon-lualine",
		auto_enable = true,
		event = "DeferredUIEnter",
	},
}
