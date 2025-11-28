return {
	{
		"bjarneo/snow.nvim",
		name = "snow",
		config = function()
			vim.o.background = "light"
			vim.cmd.colorscheme("snow")

			-- Set custom fzf colors for Snow (light theme)
			vim.g.theme_fzf_colors = {
				text_fg = "#2c2e34",      -- Snow dark text
				match_fg = "#be5046",     -- Snow red accent
				selection_bg = "#e5e5e5", -- Snow light gray
			}
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "snow",
		},
	},
}