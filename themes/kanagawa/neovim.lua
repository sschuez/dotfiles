return {
	{
		"rebelot/kanagawa.nvim",
		priority = 1000,
		config = function()
			vim.o.background = "dark"
			vim.cmd.colorscheme("kanagawa")
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "kanagawa",
		},
	},
}