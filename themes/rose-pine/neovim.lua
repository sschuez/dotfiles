return {
	{
		"rose-pine/neovim",
		name = "rose-pine",
		config = function()
			vim.o.background = "light"
			vim.cmd.colorscheme("rose-pine-dawn")

			-- Set custom fzf colors for Rose Pine Dawn
			vim.g.theme_fzf_colors = {
				text_fg = "#575279",      -- Rose Pine Dawn text
				match_fg = "#d7827e",     -- Rose Pine Dawn rose
				selection_bg = "#f2e9e1", -- Rose Pine Dawn highlight low
			}
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "rose-pine-dawn",
		},
	},
}
