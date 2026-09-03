-- Keeps expensive per-buffer machinery off files that cannot afford it.
--
-- Measured on this machine with nvim 0.12, opening the same 25MB bundle:
-- as `.txt` it cost 46MB of RSS, as `.js` an LSP attach took that to 1.2GB
-- (the whole file ships to the server in one textDocument/didOpen) and made
-- 200 cursor moves take 20 seconds. Detaching afterwards does not give the
-- memory back, so the attach has to be prevented, not undone.
--
-- Byte count alone is a poor predictor: 25MB of normal-width lines cost
-- 534MB and still scrolled in 2ms, while 4MB of minified lines cost 2.4GB.
-- Line length is the sharper signal, so both are checked.

local max_bytes = 2 * 1024 * 1024
local max_line_length = 2000

-- A minified bundle puts its longest line at the top, so scanning the head
-- decides it in one read no matter how large the file is.
local head_bytes = 256 * 1024

-- Below this, a single long line is still small enough not to matter, and
-- skipping the scan keeps the cost of opening ordinary files to one stat.
local min_bytes_to_scan = 64 * 1024

-- Syntax files, ftplugins and every vim.lsp.enable() server key off
-- 'filetype', and no config lists this one, so claiming it is what keeps all
-- three away. It has to come from detection rather than from a BufReadPre
-- autocmd: `:setf` only declines to overwrite within one sequence of
-- autocommands, and detection runs on BufRead, a sequence later.
local filetype = "bigfile"

local uv = vim.uv

local function has_long_line(path)
  local fd = uv.fs_open(path, "r", 438)
  if not fd then
    return false
  end

  local head = uv.fs_read(fd, head_bytes, 0)
  uv.fs_close(fd)
  if not head then
    return false
  end

  local pos = 1
  while true do
    local newline = head:find("\n", pos, true)
    if not newline then
      -- Whatever trails the last newline is only a fragment of its line, so
      -- this undercounts. A fragment already over the limit still decides it.
      return #head - pos + 1 > max_line_length
    end
    if newline - pos > max_line_length then
      return true
    end
    pos = newline + 1
  end
end

local function is_big(path)
  local stat = uv.fs_stat(path)
  if not stat or stat.type ~= "file" then
    return false
  end
  if stat.size > max_bytes then
    return true
  end
  return stat.size >= min_bytes_to_scan and has_long_line(path)
end

-- Outranks every built-in matcher, and returning nil falls through to them.
vim.filetype.add({
  pattern = {
    [".*"] = {
      function(path)
        if path and is_big(path) then
          return filetype
        end
      end,
      { priority = math.huge },
    },
  },
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("bigfile", { clear = true }),
  pattern = filetype,
  callback = function(args)
    -- Wrapping a 128k-column line makes every j recompute its screen lines:
    -- 30 lines took 70ms wrapped against 3ms unwrapped. Window-local to this
    -- buffer, so other files shown in the same window keep 'wrap'.
    vim.wo[0][0].wrap = false

    vim.notify(
      ("%s: opened without syntax or LSP"):format(vim.fn.fnamemodify(args.file, ":t")),
      vim.log.levels.INFO
    )
  end,
})
