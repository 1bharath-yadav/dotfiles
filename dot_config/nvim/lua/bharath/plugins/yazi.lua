return {
  "mikavilpas/yazi.nvim",
  version = "*",
  cmd = { "Yazi", "Yazi cwd" },
  keys = {
    { "<leader>fe", "<cmd>Yazi<cr>", desc = "Yazi file manager" },
    { "<leader>fw", "<cmd>Yazi cwd<cr>", desc = "Yazi working directory" },
  },
  opts = {
    open_for_directories = true,
    keymaps = { show_help = "<f1>" },
  },
}
