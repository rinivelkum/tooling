return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = {
          max_concurrent_installers = 4,
          ui = {
            check_outdated_packages_on_open = false,
          },
        },
      },
      "mason-org/mason-lspconfig.nvim",
    },
    config = function()
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

      -- mason-lspconfig v2 runs vim.lsp.enable() for every installed server,
      -- so installing is all that's needed; lspconfig provides the configs.
      require("mason-lspconfig").setup({
        ensure_installed = {
          "gopls",
          "rust_analyzer",
          "pyright",
          "html",
          "cssls",
          "tsgo",
        },
      })
    end,
  },
}
