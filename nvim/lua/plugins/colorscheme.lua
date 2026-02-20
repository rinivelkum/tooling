return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      contrast = "soft",
    },
    config = function(_, opts)
      vim.o.background = "light"
      require("gruvbox").setup(opts)
      vim.cmd.colorscheme("gruvbox")
    end,
  },
}
