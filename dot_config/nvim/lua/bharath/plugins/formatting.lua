return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_format", "black", stop_after_first = true },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      json = { "jq", "prettier", stop_after_first = true },
      jsonc = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      sh = { "shfmt" },
      bash = { "shfmt" },
      rust = { "rustfmt" },
      go = { "gofmt" },
      c = { "clang_format" },
      cpp = { "clang_format" },
      java = { "google-java-format" },
      sql = { "sql_formatter" },
    },
    formatters = {
      ruff_format = {
        command = "ruff",
        args = { "format", "--stdin-filename", "$FILENAME", "-" },
        stdin = true,
      },
      sql_formatter = {
        command = "sql-formatter",
        args = { "-l", "postgresql" },
        stdin = true,
      },
    },
    format_on_save = {
      timeout_ms = 3000,
      lsp_fallback = true,
    },
  },
  keys = {
    { "<leader>cf", function() require("conform").format({ async = true, lsp_fallback = true }) end, desc = "Format buffer" },
  },
}
