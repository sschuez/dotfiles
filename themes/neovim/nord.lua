return {
	{
		"shaunsingh/nord.nvim",
		priority = 1000,
		config = function()
			-- Set dark background for nord
			vim.o.background = "dark"
			vim.cmd.colorscheme("nord")
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "nord",
		},
	},
}