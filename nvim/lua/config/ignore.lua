local M = {}

-- Single source of truth for everything we never want to see.
local names = {
  ".git",
  "node_modules",
  "dist",
  "build",
  ".next",
  ".nuxt",
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
}

-- Only ignored when it sits directly at the search root; nested dirs like
-- packages/app/coverage stay visible.
local root_only_names = {
  "coverage",
}

-- Bare names (no slash) match at any depth, so nested dirs like
-- packages/app/node_modules are excluded too. A leading slash anchors a
-- glob to the search root instead of matching at any depth.
M.rg_globs = {}
for _, name in ipairs(names) do
  M.rg_globs[#M.rg_globs + 1] = "!" .. name
end
for _, name in ipairs(root_only_names) do
  M.rg_globs[#M.rg_globs + 1] = "!/" .. name
end

-- netrw matches each comma-separated entry as a vim regex against the
-- listed name; directories carry a trailing slash, hence the optional \/.
local function netrw_pat(name)
  return "^" .. name:gsub("%.", [[\.]]) .. [[\/\=$]]
end
local netrw_pats = {}
for _, name in ipairs(names) do
  netrw_pats[#netrw_pats + 1] = netrw_pat(name)
end
for _, name in ipairs(root_only_names) do
  netrw_pats[#netrw_pats + 1] = netrw_pat(name)
end
M.netrw_hide = table.concat(netrw_pats, ",")

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
