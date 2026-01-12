return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			vim.o.background = "light"
			require("catppuccin").setup({
				flavour = "latte", -- other options: "mocha", "frappe", "macchiato"
			})
			vim.cmd.colorscheme("catppuccin-latte")

			-- Set custom fzf colors for Catppuccin Latte
			vim.g.theme_fzf_colors = {
				text_fg = "#4c4f69",      -- Catppuccin Latte text
				match_fg = "#ea76cb",     -- Catppuccin Latte pink/mauve
				selection_bg = "#e6e9ef", -- Catppuccin Latte surface0
			}
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "catppuccin-latte",
		},
	},
}
