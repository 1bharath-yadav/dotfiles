return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>ha", function() require("harpoon"):list():add() end, desc = "Harpoon add file" },
    { "<leader>hm", function() require("harpoon").ui:toggle_quick_menu(require("harpoon"):list()) end, desc = "Harpoon menu" },
    { "<leader>h1", function() require("harpoon"):list():select(1) end, desc = "Harpoon file 1" },
    { "<leader>h2", function() require("harpoon"):list():select(2) end, desc = "Harpoon file 2" },
    { "<leader>h3", function() require("harpoon"):list():select(3) end, desc = "Harpoon file 3" },
    { "<leader>h4", function() require("harpoon"):list():select(4) end, desc = "Harpoon file 4" },
  },
  config = function() require("harpoon"):setup({}) end,
}
