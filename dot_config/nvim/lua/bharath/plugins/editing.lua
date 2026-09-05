return {
  "nvim-pack/nvim-spectre",
  cmd = { "Spectre" },
  keys = {
    { "<leader>sr", function() require("spectre").toggle() end, desc = "Replace: project" },
    { "<leader>sw", function() require("spectre").open_visual({ select_word = true }) end, mode = { "n", "x" }, desc = "Replace: word" },
    { "<leader>sf", function() require("spectre").open_file_search({ select_word = true }) end, desc = "Replace: file" },
    { "<leader>sn", function() require("spectre").open_file_search({ cwd = vim.fn.getcwd() }) end, desc = "Search/replace: cwd" },
  },
  opts = {
    is_insert_mode = true,
    live_update = false,
    highlight = { ui = "String" },
    mapping = {
      ["send_to_qf_list"] = { map = "<leader>q", cmd = "send_to_qf_list", desc = "Send to quickfix" },
      ["run_current_replace"] = { map = "<CR>", cmd = "replace_current_line", desc = "Replace current" },
      ["replace_all"] = { map = "<leader>R", cmd = "replace_all", desc = "Replace all" },
    },
  },
}
