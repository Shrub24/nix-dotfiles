return {
	{
		"igorlfs/nvim-dap-view",
		---@module 'dap-view'
		---@type dapview.Config
		opts = {
			auto_toggle = true,
			winbar = {
				controls = {
					enabled = true,
				},
			},
		},
		keys = {
			{
				"<leader>dv",
				"<cmd>DapViewToggle<cr>",
				desc = "Toggle Dap View",
			},
		},
	},
}
