vim.keymap.set("n", "<leader>e", "<cmd>Lexplore<CR>", {
  desc = "Explorer toggle",
  silent = true,
})

-- Prefix searches with \V ("very nomagic") so the pattern is literal.
-- A backslash in the pattern still needs escaping; nothing else does.
vim.keymap.set({ "n", "x", "o" }, "/", "/\\V", { desc = "Search (literal)" })
vim.keymap.set({ "n", "x", "o" }, "?", "?\\V", { desc = "Search backwards (literal)" })

