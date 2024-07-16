return {
	{
		"ellisonleao/gruvbox.nvim",
		config = function()
			-- Set the background to light or dark
			vim.o.background = "light"
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "gruvbox",
		},
	},
}
