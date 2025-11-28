return {
	{
		"ellisonleao/gruvbox.nvim",
		config = function()
			-- Set the background to light or dark
			vim.o.background = "light"
			vim.cmd.colorscheme("gruvbox")

			-- Set custom fzf colors for Gruvbox Light
			vim.g.theme_fzf_colors = {
				text_fg = "#3c3836",      -- Gruvbox Light dark text
				match_fg = "#cc241d",     -- Gruvbox Light red
				selection_bg = "#ebdbb2", -- Gruvbox Light bg1
			}
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "gruvbox",
		},
	},
}
