-- Theme — the terminal profile's own colors. With termguicolors off, highlights
-- fall back to their cterm values, and the terminal maps 0-15 from the profile
-- swatches. The `vim` scheme is the only built-in that leaves Normal undefined,
-- so the buffer keeps the terminal's background instead of painting its own.
-- Nvim queries the terminal for its background color at startup regardless of
-- this setting (gated on 'ttyfast' alone, in runtime/lua/vim/_core/defaults.lua).
-- Setting `background` explicitly deletes the TermResponse autocmd at VimEnter,
-- so a late or garbled response cannot flip the option out from under the
-- highlights below. Only light profiles are supported, so there is nothing to
-- detect either way.
vim.opt.termguicolors = false
vim.o.background = "light"

-- The `vim` scheme reaches past 15 into the xterm cube in about ten places
-- (Statement and every keyword group at 130, Visual and Folded at 248, Pmenu
-- and DiffChange at 225, ColorColumn at 224, DiffAdd at 81, DiffDelete at 159).
-- Indices 16-255 are fixed by the cube, so the profile cannot reach them and
-- those groups ignore it entirely.
--
-- The rest of the assignment is driven by the Clear Light profile's measured
-- contrast against its white background. Only five slots clear 3:1 — 0
-- (#2D3840, 12.0), 8 (#506573, 6.1), 1 (#B45648, 4.8), 4 (#5685A8, 4.0) and 5
-- (#AD64BE, 3.9). The other eleven are pastels drawn for a dark background,
-- cyan worst at 2.0. So foregrounds come from those five and the pale slots are
-- used as backgrounds only, where a wash behind dark text is what you want.
local function ansi_only()
  local set = function(group, spec)
    vim.api.nvim_set_hl(0, group, spec)
  end

  -- Variables, functions and punctuation are the most frequent tokens on
  -- screen, so they get the highest-contrast option available, which is no
  -- color at all. @lsp.type.variable, .property and .parameter link to
  -- Identifier, and Function links there too until set separately.
  set("Identifier", {})
  set("Function", {})
  set("Special", {})
  set("Comment", { ctermfg = 8 })
  set("PreProc", { ctermfg = 8 })
  set("Constant", { ctermfg = 1 })
  set("Statement", { ctermfg = 4 })
  set("Type", { ctermfg = 5 })

  -- Every ctermbg carries an explicit ctermfg, otherwise the group keeps
  -- whatever foreground it inherited and lands a pastel on a pastel.
  set("Visual", { ctermfg = 0, ctermbg = 14 })
  set("MatchParen", { ctermfg = 0, ctermbg = 6 })

  -- Slot 15 (#D8E1E7) is only 1.3:1 against the white background, so a popup
  -- painted with it has no visible edge. 7 (#C1C8CC) reads as grey.
  set("Pmenu", { ctermfg = 0, ctermbg = 7 })
  set("PmenuSel", { ctermfg = 0, ctermbg = 14 })
  set("PmenuMatch", { ctermfg = 0, ctermbg = 7, bold = true })
  set("PmenuMatchSel", { ctermfg = 0, ctermbg = 14, bold = true })
  set("PmenuSbar", { ctermbg = 15 })
  set("PmenuThumb", { ctermbg = 8 })

  set("ColorColumn", { ctermbg = 15 })
  set("Folded", { ctermfg = 8, ctermbg = 15 })
  set("LineNr", { ctermfg = 8 })
  set("CursorLineNr", { ctermfg = 0, bold = true })
  set("Conceal", { ctermfg = 8 })

  -- LspInlayHint and ComplHint link to NonText and carry text worth reading, so
  -- NonText takes a readable slot. The two groups that are meant to fade out get
  -- set directly instead of inheriting it.
  set("NonText", { ctermfg = 8 })
  set("EndOfBuffer", { ctermfg = 7 })
  set("Whitespace", { ctermfg = 7 })

  -- signcolumn and foldcolumn are off, but these two still paint when a plugin
  -- or :setlocal turns either column on.
  set("SignColumn", { ctermfg = 8 })
  set("FoldColumn", { ctermfg = 8 })

  set("SpellBad", { ctermfg = 0, ctermbg = 9 })
  set("SpellCap", { ctermfg = 0, ctermbg = 12 })
  set("SpellRare", { ctermfg = 0, ctermbg = 13 })
  set("SpellLocal", { ctermfg = 0, ctermbg = 14 })

  -- Search, the diff backgrounds and DiffText each need their own slot: a match
  -- inside a changed line, or a changed word inside a changed line, is invisible
  -- when the two share one. CurSearch and Substitute link to Search.
  set("Search", { ctermfg = 0, ctermbg = 11 })
  set("IncSearch", { ctermfg = 0, ctermbg = 3 })
  set("DiffAdd", { ctermfg = 0, ctermbg = 10 })
  set("DiffChange", { ctermfg = 0, ctermbg = 12 })
  set("DiffText", { ctermfg = 0, ctermbg = 13, bold = true })
  set("DiffDelete", { ctermfg = 0, ctermbg = 9 })

  set("DiagnosticError", { ctermfg = 1 })
  set("DiagnosticWarn", { ctermfg = 5 })
  set("DiagnosticInfo", { ctermfg = 4 })
  set("DiagnosticHint", { ctermfg = 8 })
  set("DiagnosticOk", { ctermfg = 4 })

  -- Messages and diff summaries default to slots 2, 9, 10 and 12, all of which
  -- fail 3:1 here. MoreMsg carries the "Press ENTER" prompt. PreInsert links to
  -- Added and ComplHintMore to MoreMsg.
  set("MoreMsg", { ctermfg = 4, bold = true })
  set("Question", { ctermfg = 4, bold = true })
  set("OkMsg", { ctermfg = 4 })
  set("Added", { ctermfg = 4 })
  set("Changed", { ctermfg = 5 })
  set("Removed", { ctermfg = 1 })
end

vim.api.nvim_create_autocmd("ColorScheme", { callback = ansi_only })
vim.cmd.colorscheme("vim")
