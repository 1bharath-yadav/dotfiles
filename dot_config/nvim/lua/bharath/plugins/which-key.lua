return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 300,
    spec = {
      { "<leader>c", group = "󰒓 Code" },
      { "<leader>d", group = "󰃤 Debug" },
      { "<leader>f", group = "󰱼 Find / Files" },
      { "<leader>g", group = "󰊢 Git" },
      { "<leader>h", group = "󱡅 Harpoon" },
      { "<leader>m", group = "󰍔 Markdown" },
      { "<leader>o", group = "󱞁 Obsidian" },
      { "<leader>s", group = "󰱼 Search / Replace" },
      { "<leader>t", group = "󰙨 Tests / Tabs" },
      { "<leader>u", group = "󰔡 UI" },
      { "<leader>w", group = "󱂬 Windows / Workspace" },
      { "<leader>x", group = "󰒡 Diagnostics" },
      { "<leader>?", desc = "󰋖 Keymap help" },
    },
  },
}
