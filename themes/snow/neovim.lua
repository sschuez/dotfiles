return {
	{
		"bjarneo/snow.nvim",
		name = "snow",
		config = function()
			vim.o.background = "light"
			require("snow").setup({
				highlights = {
					FloatBorder = { fg = "#808080" }, -- default is near-invisible on the transparent background
				},
			})
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