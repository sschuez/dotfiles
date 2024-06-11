return {
	{ "rktjmp/lush.nvim" },
	{
		"metalelf0/jellybeans-nvim",
		config = function()
			-- Set the background to dark
			vim.o.background = "dark"

			-- Apply the colorscheme
			vim.cmd([[colorscheme jellybeans-nvim]])
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			-- The colorscheme option here is informational for LazyVim,
			-- The actual setting is done in the config function above
			colorscheme = "jellybeans-nvim",
		},
	},
}
