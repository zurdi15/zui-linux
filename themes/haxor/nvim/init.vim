call plug#begin()
	Plug 'glepnir/dashboard-nvim'
	Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
	Plug 'nvim-lualine/lualine.nvim'
	Plug 'kyazdani42/nvim-web-devicons'
call plug#end()

lua << END
require('lualine').setup()
END

colorscheme default
syntax enable
set number