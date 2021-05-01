set autoread
set ambiwidth=double
set clipboard=unnamed
set cursorline
set cursorcolumn
set expandtab
set ignorecase
set inccommand=split
set incsearch
set noshowmode
set noswapfile
set nobackup
set number
set relativenumber
set scrolloff=1000
set sh=fish
set shiftround
set shiftwidth=2
set smartcase
set smartindent
set tabstop=2
set title
set wrapscan

augroup InitCmd
autocmd!
augroup END

" fzf
set runtimepath+=/usr/local/opt/fzf

" dein
set runtimepath+=~/.cache/dein/repos/github.com/Shougo/dein.vim

if dein#load_state('~/.cache/dein')
  call dein#begin('~/.cache/dein')

  call dein#load_toml('~/.config/nvim' . '/default.toml', {'lazy': 0})
  call dein#load_toml('~/.config/nvim' . '/file.toml', {'lazy': 0})
  call dein#load_toml('~/.config/nvim' . '/lint.toml', {'lazy': 0})
  call dein#load_toml('~/.config/nvim' . '/lsp.toml', {'lazy': 0})

  call dein#end()
  call map(dein#check_clean(), "delete(v:val, 'rf')")
  call dein#save_state()
endif

filetype plugin indent on
syntax enable
colorscheme iceberg

if has('vim_starting') && dein#check_install()
  call dein#install()
endif
