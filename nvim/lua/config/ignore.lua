local M = {}

M.rg_globs = {
  "!.git/*",
  "!node_modules/*",
  "!dist/*",
  "!build/*",
  "!.next/*",
  "!.nuxt/*",
  "!coverage/*",
  "!.venv/*",
  "!venv/*",
  "!__pycache__/*",
  "!.pytest_cache/*",
  "!.mypy_cache/*",
  "!.ruff_cache/*",
  "!target/*",
  "!vendor/*",
  "!.idea/**",
  "!.DS_Store",
}

M.lua_patterns = {
  "%.git/",
  "node_modules/",
  "dist/",
  "build/",
  "%.next/",
  "%.nuxt/",
  "coverage/",
  "%.venv/",
  "venv/",
  "__pycache__/",
  "%.pytest_cache/",
  "%.mypy_cache/",
  "%.ruff_cache/",
  "target/",
  "vendor/",
  ".idea",
  ".DS_Store",
}

M.netrw_hide = table.concat({
  ".git",
  "node_modules",
  "dist",
  "build",
  ".next",
  ".nuxt",
  "coverage",
  ".venv",
  "venv",
  "__pycache__",
  ".pytest_cache",
  ".mypy_cache",
  ".ruff_cache",
  "target",
  "vendor",
  ".idea",
  ".DS_Store",
}, ",")

function M.rg_with_ignores(base_args)
  local out = vim.deepcopy(base_args)
  for _, glob in ipairs(M.rg_globs) do
    out[#out + 1] = "--glob"
    out[#out + 1] = glob
  end
  return out
end

function M.grepprg()
  local parts = { "rg", "--vimgrep", "--smart-case", "--hidden" }
  for _, glob in ipairs(M.rg_globs) do
    parts[#parts + 1] = "--glob"
    parts[#parts + 1] = ("'%s'"):format(glob)
  end
  return table.concat(parts, " ")
end

return M
