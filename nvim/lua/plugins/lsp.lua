return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {
      max_concurrent_installers = 4,
      ui = {
        check_outdated_packages_on_open = false,
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- mason.setup() does this too, but mason only loads on :Mason now and
      -- the servers must be on PATH before vim.lsp.enable() spawns them.
      vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

      vim.diagnostic.config({
        signs = false,
        virtual_text = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- References, implementation, hover and diagnostic jumps use the
      -- built-in grr, gri, K, [d and ]d.
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local map = function(lhs, rhs, desc)
            vim.keymap.set("n", lhs, rhs, {
              buffer = args.buf,
              silent = true,
              desc = desc,
            })
          end

          map("gd", vim.lsp.buf.definition, "Go to definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        end,
      })

      -- lspconfig's tsc root_dir runs `tsc --version` synchronously (spawning
      -- node) before the first attach in each root, 30-70ms warm and up to
      -- 0.5s cold. Mason's tsc is TypeScript 7, so skip the probe.
      vim.lsp.config("tsc", {
        root_dir = function(bufnr, on_dir)
          local root = vim.fs.root(bufnr, {
            { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" },
            { ".git" },
          })
          on_dir(root or vim.fn.getcwd())
        end,
      })

      vim.lsp.enable({
        "gopls",
        "rust_analyzer",
        "pyright",
        "html",
        "cssls",
        "tsc",
      })
    end,
  },
}
