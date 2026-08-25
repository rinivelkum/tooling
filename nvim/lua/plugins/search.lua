return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    opts = function()
      local ignore = require("config.ignore")
      return {
        defaults = {
          vimgrep_arguments = ignore.rg_with_ignores({
            "rg",
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--smart-case",
            "--hidden",
          }),
          prompt_prefix = "> ",
          selection_caret = "> ",
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
            height = 0.85,
            width = 0.90,
          },
        },
        pickers = {
          find_files = {
            find_command = ignore.rg_with_ignores({
              "rg",
              "--files",
              "--hidden",
            }),
          },
          live_grep = {
            additional_args = { "--fixed-strings" },
          },
          buffers = {
            sort_lastused = true,
          },
        },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  },
}
