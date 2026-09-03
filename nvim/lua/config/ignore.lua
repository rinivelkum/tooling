local M = {}

-- Single source of truth for everything we never want to see.

-- Directories, hidden at any depth so nested dirs like
-- packages/app/node_modules are excluded too. A regular file with one of
-- these names (a repo-root `build` script, say) stays visible.
local dir_names = {
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
}

-- Hidden whether file or directory. .git is a file in worktrees and
-- submodules; .DS_Store is always a file.
local any_names = {
  ".git",
  ".DS_Store",
}

-- Only ignored when it sits directly at the search root; nested dirs like
-- packages/app/coverage stay visible.
local root_only_dir_names = {
  "coverage",
}

-- rg globs follow gitignore rules: a trailing slash matches directories only,
-- a leading slash anchors the glob to the search root instead of any depth.
M.rg_globs = {}
for _, name in ipairs(dir_names) do
  M.rg_globs[#M.rg_globs + 1] = "!" .. name .. "/"
end
for _, name in ipairs(any_names) do
  M.rg_globs[#M.rg_globs + 1] = "!" .. name
end
for _, name in ipairs(root_only_dir_names) do
  M.rg_globs[#M.rg_globs + 1] = "!/" .. name .. "/"
end

-- netrw matches each comma-separated entry as a vim regex against the
-- listed name; directories carry a trailing slash, hence the optional \/.
-- \C keeps the match case-sensitive despite 'ignorecase', so Build/ or
-- Vendor/ are not hidden.
local function netrw_pat(name)
  return [[^\C]] .. name:gsub("%.", [[\.]]) .. [[\/\=$]]
end
local netrw_pats = {}
for _, name in ipairs(dir_names) do
  netrw_pats[#netrw_pats + 1] = netrw_pat(name)
end
for _, name in ipairs(any_names) do
  netrw_pats[#netrw_pats + 1] = netrw_pat(name)
end
for _, name in ipairs(root_only_dir_names) do
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
