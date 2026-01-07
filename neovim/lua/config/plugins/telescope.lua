return {
	{
		'nvim-telescope/telescope.nvim',
		tag = '0.1.8',
		dependencies = {
			'nvim-lua/plenary.nvim',
			{ 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
		},
		config = function()
			require('telescope').setup {
				defaults = {
					file_ignore_patterns = {
						'node_modules',
					},
				},
				extensions = {
					fzf = {}
				}
			}

			require('telescope').load_extension('fzf')

			vim.keymap.set("n", "<space>f", require('telescope.builtin').find_files)
			vim.keymap.set("n", "<space>/", require('telescope.builtin').live_grep)
			vim.keymap.set("n", "<space>ht", require('telescope.builtin').help_tags)

			-- Fuzzy find nvim config files
			vim.keymap.set("n", "<space>en", function()
				require('telescope.builtin').find_files {
					cwd = "~/dotfiles/neovim/.config/nvim"
				}
			end)
		end
	}
}
