return {
  "voldikss/vim-floaterm",
  keys = {
    { "<M-t>", "<cmd>FloatermToggle<cr>", desc = "Toggle Floaterm" },
    { "<M-o>", "<cmd>FloatermNew<cr>", desc = "New Floaterm" },
    { "<M-k>", "<cmd>FloatermKill<cr>", desc = "Kill Floaterm" },
    { "<M-h>", "<cmd>FloatermPrev<cr>", desc = "Previous Floaterm" },
    { "<M-n>", "<cmd>FloatermNext<cr>", desc = "Next Floaterm" },
  },
  config = function()
    vim.g.floaterm_width = 0.8
    vim.g.floaterm_height = 0.8
    vim.g.floaterm_title = "Terminal ($1/$2)"
    vim.g.floaterm_autoclose = 2
    vim.api.nvim_set_keymap("n", "<F12>", ":FloatermToggle<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("t", "<F12>", "<C-\\><C-n>:FloatermToggle<CR>", { noremap = true, silent = true })
    vim.api.nvim_set_keymap("t", "<Esc>", "<C-\\><C-n>", { noremap = true, silent = true })
  end,
}
