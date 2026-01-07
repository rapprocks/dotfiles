return {
{
  'stevearc/oil.nvim',
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {},
  -- Optional dependencies
  dependencies = { { "echasnovski/mini.icons", opts = {} } },
  -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if prefer nvim-web-devicons
	config = function()
		require("oil").setup({
			-- Oil will take over directory buffers (e.g. `vim .` or `:e src/`)
  		-- Set to false if you want some other plugin (e.g. netrw) to open when you edit directories.
  		default_file_explorer = true,
			-- Id is automatically added at the beginning, and name at the end
  		-- See :help oil-columns
  		columns = {
    		"icon",
    		-- "permissions",
    		-- "size",
    		-- "mtime",
  		},
		})
	end,
}
}
