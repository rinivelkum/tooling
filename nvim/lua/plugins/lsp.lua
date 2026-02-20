return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
        opts = {
          max_concurrent_installers = 4,
          ui = {
            check_outdated_packages_on_open = false,
          },
        },
      },
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      if not (vim.lsp.config and vim.lsp.enable) then
        vim.notify("This LSP config requires Neovim 0.11+", vim.log.levels.ERROR)
        return
      end

      vim.diagnostic.config({
        signs = false,
        virtual_text = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      vim.keymap.set("n", "[d", function()
        vim.diagnostic.jump({ count = -1, float = false })
      end, {
        desc = "Previous diagnostic",
        silent = true,
      })
      vim.keymap.set("n", "]d", function()
        vim.diagnostic.jump({ count = 1, float = false })
      end, {
        desc = "Next diagnostic",
        silent = true,
      })

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
          map("gi", vim.lsp.buf.implementation, "Go to implementation")
          map("gr", vim.lsp.buf.references, "Go to references")
          map("K", vim.lsp.buf.hover, "Hover")
          map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action")
        end,
      })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      local servers = {
        gopls = { capabilities = capabilities },
        rust_analyzer = { capabilities = capabilities },
        pyright = { capabilities = capabilities },
        html = { capabilities = capabilities },
        cssls = { capabilities = capabilities },
      }

      local enabled = {
        "gopls",
        "rust_analyzer",
        "pyright",
        "html",
        "cssls",
      }

      local ts_server = nil
      if vim.lsp.config.ts_ls then
        ts_server = "ts_ls"
      end
      if ts_server then
        servers[ts_server] = { capabilities = capabilities }
        enabled[#enabled + 1] = ts_server
      end

      require("mason-lspconfig").setup({
        ensure_installed = enabled,
        automatic_installation = true,
      })

      for name, opts in pairs(servers) do
        vim.lsp.config(name, opts)
      end
      for _, name in ipairs(enabled) do
        vim.lsp.enable(name)
      end
    end,
  },
}
