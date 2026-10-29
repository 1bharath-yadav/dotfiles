return {
  "nvim-neotest/neotest",
  dependencies = { "nvim-neotest/nvim-nio", "antoinemadec/FixCursorHold.nvim", "nvim-neotest/neotest-python", "nvim-neotest/neotest-plenary" },
  keys = {
    { "<leader>tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
    { "<leader>tT", function() require("neotest").run.run(vim.fn.getcwd()) end, desc = "Run test suite" },
    { "<leader>to", function() require("neotest").output.open({ enter = true }) end, desc = "Test output" },
    { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Test summary" },
  },
  config = function()
    require("neotest").setup({
      adapters = { require("neotest-python")({ runner = "pytest" }), require("neotest-plenary") },
      output = { open_on_run = "short" },
      output_panel = { enabled = true, open = "botright split | resize 15" },
    })
  end,
}
