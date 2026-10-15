return {
	{
		"tahayvr/matteblack.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			vim.o.background = "dark"
			-- matteblack has no override option, and LazyVim loads the colorscheme again after this
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = vim.api.nvim_create_augroup("matteblack_overrides", { clear = true }),
				pattern = "matteblack",
				callback = function()
					-- default is near-invisible on the transparent background
					vim.api.nvim_set_hl(0, "FloatBorder", { fg = "#8A8A8D" })
				end,
			})
			vim.cmd.colorscheme("matteblack")
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "matteblack",
		},
	},
}