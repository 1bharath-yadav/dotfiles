vim.g.mapleader = " "
local map = vim.keymap.set

-- Core editing
map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<C-s>", "<cmd>w<CR>", { desc = "Save file" })
map({ "n", "v" }, "<leader>cf", function() require("conform").format({ async = true, lsp_fallback = true }) end, { desc = "Format code" })
map("n", "<leader>cl", function() require("lint").try_lint() end, { desc = "Lint buffer" })

-- Counts / line editing
map("n", ">>", ">>_", { desc = "Indent line" })
map("n", "<<", "<<_", { desc = "Outdent line" })
map("n", "J", "mzJ`z", { desc = "Join line and keep cursor" })
map("n", "n", "nzzzv", { desc = "Next match centered" })
map("n", "N", "Nzzzv", { desc = "Previous match centered" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half-page down centered" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half-page up centered" })
map("n", "<leader>+", "<cmd>normal! <C-a><CR>", { desc = "Increment number" })
map("n", "<leader>-", "<cmd>normal! <C-x><CR>", { desc = "Decrement number" })

-- Fast window management
map("n", "<leader>wh", "<C-w>h", { desc = "Window left" })
map("n", "<leader>wj", "<C-w>j", { desc = "Window down" })
map("n", "<leader>wk", "<C-w>k", { desc = "Window up" })
map("n", "<leader>wl", "<C-w>l", { desc = "Window right" })
map("n", "<leader>wv", "<C-w>v", { desc = "Vertical split" })
map("n", "<leader>ws", "<C-w>s", { desc = "Horizontal split" })
map("n", "<leader>we", "<C-w>=", { desc = "Equalize windows" })
map("n", "<leader>wx", "<cmd>close<CR>", { desc = "Close window" })
map("n", "<leader>wz", "<C-w>|<C-w>_", { desc = "Maximize window" })

-- Buffers / tabs
map("n", "<leader>bb", "<cmd>e #<CR>", { desc = "Alternate buffer" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>bo", "<cmd>%bd|e#|bd#<CR>", { desc = "Delete other buffers" })
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>tn", "<cmd>tabnext<CR>", { desc = "Next tab" })
map("n", "<leader>tp", "<cmd>tabprevious<CR>", { desc = "Previous tab" })

-- File/path helpers
map("n", "<leader>fp", function() vim.fn.setreg("+", vim.fn.expand("%:p")) end, { desc = "Copy file path" })
map("n", "<leader>fn", function() vim.fn.setreg("+", vim.fn.expand("%:t")) end, { desc = "Copy file name" })
map("n", "<leader>fc", "<cmd>cd %:p:h<CR>", { desc = "Change cwd to file" })

-- Diagnostics / quickfix / location list
map("n", "<leader>xd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "<leader>xl", vim.diagnostic.setloclist, { desc = "Diagnostics location list" })
map("n", "<leader>xq", "<cmd>copen<CR>", { desc = "Quickfix list" })
map("n", "<leader>xQ", "<cmd>cclose<CR>", { desc = "Close quickfix" })
map("n", "[q", "<cmd>cprev<CR>zz", { desc = "Previous quickfix" })
map("n", "]q", "<cmd>cnext<CR>zz", { desc = "Next quickfix" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })

-- Search / replace
map("n", "*", "*N", { desc = "Search word forward" })
map("n", "#", "#n", { desc = "Search word backward" })
map("n", "<leader>ss", function() require("snacks").picker.grep_word() end, { desc = "Search current word" })

-- Code navigation
map("n", "gD", vim.lsp.buf.declaration, { desc = "LSP declaration" })
map("n", "gd", vim.lsp.buf.definition, { desc = "LSP definition" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "LSP implementation" })
map("n", "gt", vim.lsp.buf.type_definition, { desc = "LSP type definition" })
map("n", "gr", vim.lsp.buf.references, { desc = "LSP references" })
map("n", "K", vim.lsp.buf.hover, { desc = "LSP hover" })
map("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>cr", vim.lsp.buf.rename, { desc = "Rename symbol" })

-- Keep Which-Key one keystroke away
map("n", "<leader>?", "<cmd>WhichKey<CR>", { desc = "Show keymaps" })
