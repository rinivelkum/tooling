vim.keymap.set("n", "<leader>e", "<cmd>Lexplore<CR>", {
  desc = "Explorer toggle",
  silent = true,
})

-- Prefix searches with \V ("very nomagic") so the pattern is literal.
-- A backslash and the search delimiter (/ or ?) still need escaping; nothing
-- else does.
vim.keymap.set({ "n", "x", "o" }, "/", "/\\V", { desc = "Search (literal)" })
vim.keymap.set({ "n", "x", "o" }, "?", "?\\V", { desc = "Search backwards (literal)" })

-- With \V pre-typed, an empty <CR> would search for "\V" itself instead of
-- repeating the last pattern, and <Up> would only recall history entries that
-- start with \V. Clear the prefix first in both cases.
local function bare_search_prefix()
  return vim.fn.getcmdtype():match("[/?]") ~= nil and vim.fn.getcmdline() == "\\V"
end

vim.keymap.set("c", "<CR>", function()
  return bare_search_prefix() and "<C-u><CR>" or "<CR>"
end, { expr = true, desc = "Repeat last search on empty pattern" })

vim.keymap.set("c", "<Up>", function()
  return bare_search_prefix() and "<C-u><Up>" or "<Up>"
end, { expr = true, desc = "Search history recall ignoring the \\V prefix" })
