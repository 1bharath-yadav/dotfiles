return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-neotest/neotest-python",
    "nvim-neotest/neotest-plenary",
  },
  keys = {
    { "<leader>tr", function() require("neotest").run.run() end, desc = "󰙨 Test nearest" },
    { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "󰙨 Test file" },
    { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
    { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Test summary" },
    { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Test output" },
    { "<leader>tp", function() require("neotest").output_panel.toggle() end, desc = "Test output panel" },
    { "<leader>tx", function() require("neotest").run.stop() end, desc = "Stop test" },
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-python")({ dap = { justMyCode = false } }),
        require("neotest-plenary"),
      },
      output = { open_on_run = "short" },
      output_panel = { enabled = true, open = "botright split | resize 15" },
    })
  end,
}
