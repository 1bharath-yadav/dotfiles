return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {},
  keys = {
    { "<leader>ws", function() require("persistence").load() end, desc = "Workspace restore" },
    { "<leader>wl", function() require("persistence").load({ last = true }) end, desc = "Workspace restore last" },
    { "<leader>wd", function() require("persistence").stop() end, desc = "Workspace stop save" },
  },
}
