local opt = vim.opt
local ignore = require("config.ignore")

-- Minimal UI
opt.number = false
opt.relativenumber = false
opt.signcolumn = "no"
opt.foldcolumn = "0"
opt.numberwidth = 1
opt.showmode = false

-- Scrolling — one line per mouse-wheel notch (default ver:3 jumps 3 lines)
opt.mousescroll = "ver:1,hor:6"

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
opt.wrap = false

-- ftplugin/python.vim calls has('python3'), which spawns python3 to look for
-- the pynvim module (~37ms on the first Python buffer). Remote plugins are
-- disabled (rplugin) so the provider is never used.
vim.g.loaded_python3_provider = 0

-- Fast grep via ripgrep
opt.grepprg = ignore.grepprg()
opt.grepformat = "%f:%l:%c:%m"

-- Theme base — Gruvbox when the shell's `theme` says so, the terminal's own
-- palette otherwise. $THEME comes from .zshrc; the TERM_PROGRAM fallback covers
-- nvim launched outside that shell, where Ghostty still means Gruvbox.
-- With termguicolors off, highlights fall back to their cterm values, most of
-- which are ANSI 0-15 that the terminal maps from its profile colors. The `vim`
-- scheme is the only built-in that leaves Normal undefined, so the buffer keeps
-- the terminal's background instead of painting its own.
-- plugins/colorscheme.lua reads vim.g.tooling_gruvbox to load the plugin on the
-- same condition, which works because init.lua requires this file before lazy.
-- Setting `background` explicitly drops Nvim's OSC 11 query, which is the point:
-- every profile here is light, so there is nothing to detect.
local gruvbox = vim.env.THEME == "gruvbox"
  or (vim.env.THEME == nil and vim.env.TERM_PROGRAM == "ghostty")
vim.g.tooling_gruvbox = gruvbox
opt.termguicolors = gruvbox
vim.o.background = "light"
if not gruvbox then
  vim.cmd.colorscheme("vim")
end

-- Built-in lightweight explorer (netrw)
vim.g.netrw_banner = 0
vim.g.netrw_keepdir = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 19
vim.g.netrw_hide = 1
vim.g.netrw_mousemaps = 0
vim.g.netrw_list_hide = ignore.netrw_hide
