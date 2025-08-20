return {
	{
		"neanias/everforest-nvim",
		config = function()
			-- Set the background to light or dark
			vim.o.background = "light"

			-- Configure and load the everforest theme
			require("everforest").setup({
				-- Optional: Your specific configuration here
			})

			-- Apply the colorscheme
			vim.cmd([[colorscheme everforest]])
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "everforest",
		},
	},
}
