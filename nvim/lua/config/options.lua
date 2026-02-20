local opt = vim.opt
local ignore = require("config.ignore")

-- Minimal UI
opt.number = false
opt.relativenumber = false
opt.signcolumn = "no"
opt.foldcolumn = "0"
opt.numberwidth = 1
opt.showmode = false

-- Responsiveness
opt.updatetime = 200
opt.timeoutlen = 300
opt.swapfile = false
opt.backup = false
opt.undofile = true

-- Editing/search defaults
opt.ignorecase = true
opt.smartcase = true
opt.splitbelow = true
opt.splitright = true
opt.clipboard = "unnamedplus"

-- Fast grep via ripgrep
opt.grepprg = ignore.grepprg()
opt.grepformat = "%f:%l:%c:%m"

-- Theme base
opt.termguicolors = true
vim.o.background = "light"

-- Built-in lightweight explorer (netrw)
vim.g.netrw_banner = 0
vim.g.netrw_keepdir = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 24
vim.g.netrw_hide = 1
vim.g.netrw_list_hide = ignore.netrw_hide
