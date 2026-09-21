return {
	{
		"folke/sidekick.nvim",
		opts = {
			cli = {
				-- keys = {},
				watch = true,
				mux = {
					backend = "tmux",
					enabled = false,
				},
			},
		},
	},
}
