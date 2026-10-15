return {
	{
		"loctvl842/monokai-pro.nvim",
		config = function()
			vim.o.background = "dark"
			require("monokai-pro").setup({
				filter = "ristretto",
				override = function()
					return {
						NonText = { fg = "#948a8b" },
						FloatBorder = { fg = "#948a8b" }, -- default is near-invisible on the transparent background
						MiniIconsGrey = { fg = "#948a8b" },
						MiniIconsRed = { fg = "#fd6883" },
						MiniIconsBlue = { fg = "#85dacc" },
						MiniIconsGreen = { fg = "#adda78" },
						MiniIconsYellow = { fg = "#f9cc6c" },
						MiniIconsOrange = { fg = "#f38d70" },
						MiniIconsPurple = { fg = "#a8a9eb" },
						MiniIconsAzure = { fg = "#a8a9eb" },
						MiniIconsCyan = { fg = "#85dacc" }, -- same value as MiniIconsBlue for consistency
					}
				end,
			})
			vim.cmd([[colorscheme monokai-pro-ristretto]])
		end,
	},
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "monokai-pro-ristretto",
		},
	},
}
