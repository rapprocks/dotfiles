vim.g.mapleader = " "

require("config.lazy")
require("config.options")
require("config.keymaps")

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function(args)
		require("conform").format({ bufnr = args.buf })
	end,
})
