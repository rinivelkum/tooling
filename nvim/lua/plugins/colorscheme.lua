return {
  {
    "sainnhe/gruvbox-material",
    -- config/options.lua decides; other terminals keep their own palette.
    -- `cond` rather than `enabled` so the plugin stays installed and
    -- `:Lazy clean` doesn't drop it when run from Terminal.app.
    cond = function()
      return vim.g.tooling_gruvbox
    end,
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = "medium"
      vim.g.gruvbox_material_better_performance = 1
      vim.cmd.colorscheme("gruvbox-material")
    end,
  },
}
