return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    linters_by_ft = {
      python = { "ruff", "pylint" },
      javascript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescript = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      json = { "jsonlint" },
      markdown = { "markdownlint" },
      yaml = { "yamllint" },
      shell = { "shellcheck" },
      sh = { "shellcheck" },
      bash = { "shellcheck" },
      dockerfile = { "hadolint" },
      sql = { "sqlfluff" },
    },
  },
  config = function(_, opts)
    local lint = require("lint")
    lint.linters_by_ft = opts.linters_by_ft
    local group = vim.api.nvim_create_augroup("bharath-lint", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = group,
      callback = function()
        lint.try_lint()
      end,
    })
    vim.keymap.set("n", "<leader>cl", function() lint.try_lint() end, { desc = "Lint buffer" })
  end,
}
