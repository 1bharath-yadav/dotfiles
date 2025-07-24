require("bharath.core")
require("bharath.lazy")

-- Floating terminal toggle function
local floating_term_win = nil
local floating_term_buf = nil

function ToggleFloatingTerminal()
  if floating_term_win and vim.api.nvim_win_is_valid(floating_term_win) then
    -- If terminal is open, close it
    vim.api.nvim_win_hide(floating_term_win)
    floating_term_win = nil
  else
    if not floating_term_buf or not vim.api.nvim_buf_is_valid(floating_term_buf) then
      -- Create buffer if it doesn't exist
      floating_term_buf = vim.api.nvim_create_buf(false, true)
      vim.bo[floating_term_buf].bufhidden = "hide" -- Keeps the buffer after closing
      vim.bo[floating_term_buf].filetype = "terminal"
      vim.fn.termopen(vim.o.shell)
    end

    -- Get screen dimensions
    local width = vim.o.columns
    local height = vim.o.lines

    -- Open floating window with the same buffer
    floating_term_win = vim.api.nvim_open_win(floating_term_buf, true, {
      relative = "editor",
      width = math.ceil(width * 0.7),
      height = math.ceil(height * 0.7),
      row = math.ceil(height * 0.15),
      col = math.ceil(width * 0.15),
      style = "minimal",
      border = "rounded",
    })

    -- Set keymap to close terminal with 'q'
    vim.api.nvim_buf_set_keymap(floating_term_buf, "t", "q", "<C-\\><C-n>:q!<CR>", { noremap = true, silent = true })
  end
end

-- Keybinding for ALT + F to toggle the floating terminal
vim.api.nvim_set_keymap("n", "<M-f>", ":lua ToggleFloatingTerminal()<CR>", { noremap = true, silent = true })
