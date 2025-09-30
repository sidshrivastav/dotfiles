call plug#begin()

" Essential plugins
Plug 'neovim/nvim-lspconfig'                    " LSP configuration
Plug 'hrsh7th/nvim-cmp'                         " Autocompletion
Plug 'hrsh7th/cmp-nvim-lsp'                     " LSP completion source
Plug 'hrsh7th/cmp-buffer'                       " Buffer completion source
Plug 'hrsh7th/cmp-path'                         " Path completion source
Plug 'L3MON4D3/LuaSnip'                         " Snippet engine
Plug 'saadparwaiz1/cmp_luasnip'                 " Snippet completion source

" Telescope - Fuzzy finder
Plug 'nvim-lua/plenary.nvim'                    " Required for Telescope
Plug 'nvim-telescope/telescope.nvim', { 'branch': '0.1.x' }
Plug 'nvim-telescope/telescope-fzf-native.nvim', { 'do': 'make' }

" Python-specific
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'psf/black', { 'branch': 'stable' }        " Python formatter

" UI enhancements
Plug 'rose-pine/neovim', {'as': 'rose-pine'}                   " Colorscheme
Plug 'nvim-lualine/lualine.nvim'                " Status line

call plug#end()

set number                      " Show line numbers
set relativenumber              " Relative line numbers
set expandtab                   " Use spaces instead of tabs
set shiftwidth=4                " Indent by 4 spaces
set tabstop=4                   " Tab shows as 4 spaces
set softtabstop=4               " Backspace deletes 4 spaces
set smartindent                 " Smart indentation
set ignorecase                  " Case insensitive search
set smartcase                   " Unless capital letters used
set clipboard=unnamedplus       " Use system clipboard
set signcolumn=yes              " Always show sign column
set updatetime=300              " Faster completion
set timeoutlen=500              " Faster key sequence completion
set termguicolors               " True color support
set scrolloff=8                 " Keep 8 lines visible when scrolling
set splitright                  " Vertical splits go right
set splitbelow                  " Horizontal splits go below

" Colorscheme
colorscheme rose-pine

" ============================================
" Key Mappings
" ============================================
" Set leader key to space
let mapleader = " "

" General keybindings
nnoremap <leader>w :w<CR>                       
nnoremap <leader>q :q<CR>                       
nnoremap <leader>h :noh<CR>                 
nnoremap <leader>e :Ex<CR>
nnoremap <leader>km :call ShowKeymaps()<CR>

" Telescope keybindings
nnoremap <leader>ff <cmd>Telescope find_files<cr>   
nnoremap <leader>fg <cmd>Telescope live_grep<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>              
nnoremap <leader>fh <cmd>Telescope help_tags<cr>            
nnoremap <leader>fr <cmd>Telescope oldfiles<cr>             
nnoremap <leader>fc <cmd>Telescope commands<cr>
nnoremap <leader>fk <cmd>Telescope keymaps<cr>  

" LSP keybindings (set in Lua config below)
" These will be available when LSP attaches to a buffer:
" <leader>gd - Go to definition
" <leader>gD - Go to declaration
" <leader>gr - Find references (list usages)
" <leader>gi - Go to implementation
" <leader>gt - Go to type definition
" <leader>rn - Rename symbol
" <leader>ca - Code actions
" K - Hover documentation
" <leader>f - Format document
" [d - Previous diagnostic
" ]d - Next diagnostic
" <leader>d - Show line diagnostics

" ============================================
" Lua Configuration
" ============================================
lua << EOF

-- LSP Configuration using vim.lsp.config (new API)
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Global keybindings for LSP (applies when LSP attaches)
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { noremap=true, silent=true, buffer=args.buf }
    
    -- Navigation
    vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', '<leader>gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', '<leader>gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<leader>gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<leader>gt', vim.lsp.buf.type_definition, opts)
    
    -- Hover and help
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    
    -- Code actions
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', '<leader>f', function() vim.lsp.buf.format { async = true } end, opts)
    
    -- Diagnostics
    vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
    vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
    vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)
  end,
})

-- Python LSP setup using vim.lsp.config (new API)
vim.lsp.config.pyright = {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true,
        typeCheckingMode = "basic"
      }
    }
  },
  capabilities = capabilities,
}

-- Enable pyright for Python files
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'python',
  callback = function()
    vim.lsp.enable('pyright')
  end,
})

-- Autocompletion setup
local cmp = require('cmp')
local luasnip = require('luasnip')

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  }, {
    { name = 'buffer' },
    { name = 'path' },
  })
})

-- Telescope setup
require('telescope').setup{
  defaults = {
    file_ignore_patterns = { "node_modules", ".git/", "__pycache__", "*.pyc" },
    mappings = {
      i = {
        ["<C-j>"] = "move_selection_next",
        ["<C-k>"] = "move_selection_previous",
      }
    }
  },
  pickers = {
    find_files = {
      hidden = true
    }
  }
}

-- Load fzf extension for better performance
pcall(require('telescope').load_extension, 'fzf')

-- Treesitter setup
require('nvim-treesitter.configs').setup {
  ensure_installed = { "python", "lua", "vim", "json", "yaml" },
  highlight = {
    enable = true,
  },
  indent = {
    enable = true,
  }
}

-- Lualine setup
require('lualine').setup {
  options = {
    theme = 'rose-pine',
    icons_enabled = true,
  }
}

EOF

" ============================================
" Custom Keymap Documentation Function
" ============================================
function! ShowKeymaps()
  " Create a new buffer
  new
  setlocal buftype=nofile
  setlocal bufhidden=wipe
  setlocal noswapfile
  setlocal nowrap
  setlocal filetype=markdown

  " Add title and content
  call setline(1, '# Custom Keymaps')
  call append(line('$'), '')
  call append(line('$'), '> Press `q` to close this window')
  call append(line('$'), '')
  call append(line('$'), '---')
  call append(line('$'), '')

  " General Keymaps
  call append(line('$'), '## General')
  call append(line('$'), '')
  call append(line('$'), '| Key | Action |')
  call append(line('$'), '|-----|--------|')
  call append(line('$'), '| `<Space>w` | Save file |')
  call append(line('$'), '| `<Space>q` | Quit |')
  call append(line('$'), '| `<Space>h` | Clear search highlight |')
  call append(line('$'), '| `<Space>e` | Open file explorer (netrw) |')
  call append(line('$'), '| `<Space>km` | Show this keymap reference |')
  call append(line('$'), '')

  " Telescope Keymaps
  call append(line('$'), '## Telescope (Fuzzy Finder)')
  call append(line('$'), '')
  call append(line('$'), '| Key | Action |')
  call append(line('$'), '|-----|--------|')
  call append(line('$'), '| `<Space>ff` | Find files |')
  call append(line('$'), '| `<Space>fg` | Live grep (search in files) |')
  call append(line('$'), '| `<Space>fb` | Find buffers |')
  call append(line('$'), '| `<Space>fh` | Help tags |')
  call append(line('$'), '| `<Space>fr` | Recent files |')
  call append(line('$'), '| `<Space>fc` | Commands |')
  call append(line('$'), '| `<Space>fk` | Show all keymaps (native) |')
  call append(line('$'), '')
  call append(line('$'), '**Inside Telescope:**')
  call append(line('$'), '- `<C-j>` - Move selection down')
  call append(line('$'), '- `<C-k>` - Move selection up')
  call append(line('$'), '')

  " LSP Keymaps
  call append(line('$'), '## LSP Navigation & Code Actions')
  call append(line('$'), '')
  call append(line('$'), '| Key | Action |')
  call append(line('$'), '|-----|--------|')
  call append(line('$'), '| `<Space>gd` | Go to definition |')
  call append(line('$'), '| `<Space>gD` | Go to declaration |')
  call append(line('$'), '| `<Space>gr` | Find references (list usages) |')
  call append(line('$'), '| `<Space>gi` | Go to implementation |')
  call append(line('$'), '| `<Space>gt` | Go to type definition |')
  call append(line('$'), '| `K` | Hover documentation |')
  call append(line('$'), '| `<C-k>` | Signature help |')
  call append(line('$'), '| `<Space>rn` | Rename symbol |')
  call append(line('$'), '| `<Space>ca` | Code actions |')
  call append(line('$'), '| `<Space>f` | Format document |')
  call append(line('$'), '')

  " Diagnostics
  call append(line('$'), '## Diagnostics (Errors & Warnings)')
  call append(line('$'), '')
  call append(line('$'), '| Key | Action |')
  call append(line('$'), '|-----|--------|')
  call append(line('$'), '| `[d` | Previous diagnostic |')
  call append(line('$'), '| `]d` | Next diagnostic |')
  call append(line('$'), '| `<Space>d` | Show line diagnostics |')
  call append(line('$'), '')

  " Completion
  call append(line('$'), '## Autocompletion')
  call append(line('$'), '')
  call append(line('$'), '| Key | Action |')
  call append(line('$'), '|-----|--------|')
  call append(line('$'), '| `<C-Space>` | Trigger completion |')
  call append(line('$'), '| `<Tab>` | Next completion item / expand snippet |')
  call append(line('$'), '| `<S-Tab>` | Previous completion item |')
  call append(line('$'), '| `<CR>` | Confirm selection |')
  call append(line('$'), '| `<C-e>` | Abort completion |')
  call append(line('$'), '| `<C-b>` | Scroll docs up |')
  call append(line('$'), '| `<C-f>` | Scroll docs down |')
  call append(line('$'), '')

  " File Explorer
  call append(line('$'), '## File Explorer (netrw)')
  call append(line('$'), '')
  call append(line('$'), '| Key | Action |')
  call append(line('$'), '|-----|--------|')
  call append(line('$'), '| `<Enter>` | Open file/directory |')
  call append(line('$'), '| `-` | Go up one directory |')
  call append(line('$'), '| `d` | Create directory |')
  call append(line('$'), '| `%` | Create new file |')
  call append(line('$'), '| `D` | Delete file/directory |')
  call append(line('$'), '| `R` | Rename file |')
  call append(line('$'), '')

  " Tips
  call append(line('$'), '---')
  call append(line('$'), '')
  call append(line('$'), '## Tips')
  call append(line('$'), '')
  call append(line('$'), '- Leader key is `<Space>`')
  call append(line('$'), '- Most LSP features require pyright to be running')
  call append(line('$'), '- Use `:checkhealth` to verify LSP setup')
  call append(line('$'), '- Use `:LspInfo` to see active language servers')

  " Set buffer options
  setlocal nomodifiable
  setlocal readonly

  " Add quit mapping for this buffer
  nnoremap <buffer> q :q<CR>

  " Go to the top of the buffer
  normal! gg
endfunction
