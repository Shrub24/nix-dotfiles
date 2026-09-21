return {
	{
		"agda/cornelis",
		ft = "agda",
		dependencies = {
			"neovimhaskell/haskell-vim",
			"kana/vim-textobj-user",
		},
		build = nil,

		opts = {
			no_agda_input = 1,
			use_global_binary = 1,
			agda_args = { "--no-libraries" },
		},

		config = function(_, opts)
			for k, v in pairs(opts) do
				vim.g["cornelis_" .. k] = v
			end

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "agda",
				callback = function(event)
					local map = vim.keymap.set
					local opts = { buffer = event.buf, silent = true }

					local function bind(key, cmd, desc)
						map("n", key, cmd, vim.tbl_extend("force", opts, { desc = desc }))
					end

					bind("<C-a>", "<cmd>CornelisInc<CR>", "Increment / Next Solution")
					bind("<C-x>", "<cmd>CornelisDec<CR>", "Decrement / Prev Solution")
					bind("<localleader><space>", "<cmd>CornelisGive<CR>", "Give (Fill Hole)")

					-- GLOBAL
					bind("<localleader>l", "<cmd>CornelisLoad<CR>", "Load File")
					bind("<localleader>r", "<cmd>CornelisRefine<CR>", "Refine Hole")
					bind("<localleader>c", "<cmd>CornelisMakeCase<CR>", "Make Case")
					bind("<localleader>a", "<cmd>CornelisAuto<CR>", "Auto Proof Search")
					bind("<localleader>s", "<cmd>CornelisSolve<CR>", "Auto / Solve")
					bind("<localleader>n", "<cmd>CornelisNormalize<CR>", "Compute Norm")
					bind("<localleader>d", "<cmd>CornelisTypeInfer<CR>", "Infer Type")
					bind("<localleader>w", "<cmd>CornelisWhyInScope<CR>", "Why In Scope")
					bind("<localleader>?", "<cmd>CornelisGoals<CR>", "Show All Goals")

					-- GOALS / CONTEXT
					bind("<localleader>,", "<cmd>CornelisTypeContext<CR>", "Goal Context")
					bind("<localleader>.", "<cmd>CornelisTypeContextInfer<CR>", "Goal Type + Infer")

					-- NAVIGATION
					bind("<localleader>f", "<cmd>CornelisNextGoal<CR>", "Next Goal")
					bind("<localleader>b", "<cmd>CornelisPrevGoal<CR>", "Prev Goal")
					bind("gd", "<cmd>CornelisGoToDefinition<CR>", "Go to Definition")
					--
					-- BACKEND (The 'x' prefix)
					bind("<localleader>xr", "<cmd>CornelisRestart<CR>", "Restart Backend")
					bind("<localleader>xa", "<cmd>CornelisAbort<CR>", "Abort Command")

					require("which-key").add({ { "<localleader>x", group = "Agda Backend", buffer = event.buf } })
				end,
			})
		end,
	},
}
