call plug#begin()
	Plug 'dracula/vim', { 'as': 'dracula' }
	Plug 'glepnir/dashboard-nvim'
	Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
	Plug 'nvim-lualine/lualine.nvim'
	Plug 'kyazdani42/nvim-web-devicons'
call plug#end()

lua << END
require('lualine').setup()
END

colorscheme dracula
syntax enable
set number