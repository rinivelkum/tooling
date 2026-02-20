return {
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      vim.o.background = "light"
      vim.g.gruvbox_material_background = "medium"
      vim.cmd.colorscheme("gruvbox-material")
    end,
  },
}
