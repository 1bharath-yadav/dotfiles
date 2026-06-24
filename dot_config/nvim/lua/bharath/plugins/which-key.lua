return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 500
  end,
  opts = {
    spec = {
      { "<leader>b", group = "Buffers" },
      { "<leader>f", group = "Find / Picker" },
      { "<leader>g", group = "Git" },
      { "<leader>h", group = "Git Hunks" },
      { "<leader>s", group = "Search / Replace" },
      { "<leader>t", group = "Tabs" },
      { "<leader>u", group = "UI Toggles" },
      { "<leader>x", group = "Trouble / Diagnostics" },
    },
  },
}
