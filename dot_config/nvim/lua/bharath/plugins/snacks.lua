-- snacks.lua — folke/snacks.nvim: all-in-one UI & utilities
-- Replaces: telescope, alpha-nvim, nvim-tree, indent-blankline, zen-mode,
--           twilight, vim-maximizer, kdheepak/lazygit.nvim, dressing.nvim

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  ---@type snacks.Config
  opts = {
    -- ── Core ────────────────────────────────────────────────────────────
    bigfile = { enabled = true },
    quickfile = { enabled = true }, -- fast file open before plugins load
    input = { enabled = true }, -- vim.ui.input replacement (replaces dressing.nvim)
    statuscolumn = { enabled = true },
    scroll = { enabled = true }, -- smooth scrolling
    words = { enabled = true }, -- highlight + jump LSP references under cursor
    scope = { enabled = true }, -- treesitter scope detection + textobjects
    toggle = { enabled = true }, -- toggle keymaps with which-key integration
    rename = { enabled = true }, -- LSP-integrated file rename

    -- ── Styles ──────────────────────────────────────────────────────────
    styles = {
      input = {
        relative = "editor",
      },
      terminal = {
        position = "float", 
      },
    },

    -- ── Visual ──────────────────────────────────────────────────────────
    indent = { enabled = true, char = "┊" }, -- indent guides (replaces indent-blankline)
    dim = { enabled = true }, -- dim unfocused scope (replaces twilight.nvim)
    zen = { enabled = true }, -- zen mode (replaces zen-mode.nvim + vim-maximizer)
    image = { enabled = false }, -- disabled to prevent freezing when opening markdown with images
    animate = { enabled = true }, -- smooth animations for scroll/indent

    -- ── Notifier ────────────────────────────────────────────────────────
    notifier = { enabled = true, timeout = 3000, style = "compact" },

    -- ── Git ─────────────────────────────────────────────────────────────
    lazygit = { enabled = true },
    git = { enabled = true }, -- git utilities (blame etc.)
    gitbrowse = { enabled = true }, -- open file/repo in browser

    -- ── Terminal ────────────────────────────────────────────────────────
    terminal = { enabled = true },

    -- ── Buffers & Scratch ───────────────────────────────────────────────
    bufdelete = { enabled = true }, -- delete buffers without layout disruption
    scratch = { enabled = true }, -- persistent scratch buffers

    -- ── File explorer (replaces nvim-tree) ──────────────────────────────
    explorer = { enabled = true, replace_netrw = true },

    -- ── GitHub CLI ──────────────────────────────────────────────────────
    gh = { enabled = true },

    -- ── Picker (replaces telescope for all common sources) ──────────────
    picker = {
      enabled = true,
      layout = {
        -- input bar in the middle (between list and preview), not on top
        preset = "telescope",
        reverse = false, -- list above input
      },
      sources = {
        explorer = {
          -- File explorer should look like a sidebar and start in normal mode
          -- This ensures file management keys (a, d, r, c, m) work immediately
          focus = "list",
          layout = {
            preset = "sidebar",
            preview = false,
          },
        },
      },
    },

    -- ── Dashboard (replaces alpha-nvim) ─────────────────────────────────
    dashboard = {
      enabled = true,
      sections = {
        { section = "header" },
        { section = "keys", gap = 1, padding = 1 },
        { section = "startup" },
      },
      preset = {
        header = table.concat({
          "    ⟨ψ| Ĥ |ψ⟩  ·  ∇·∂t  ·  Σ(xᵢ − μ)²  ·  𝔼[X|Y]  ·  ΔS ≥ 0    ",
        }, "\n"),
        ---@type snacks.dashboard.Item[]
        keys = {
          { icon = "⊕ ", key = "e", desc = "New File",        action = ":ene | startinsert" },
          {
            icon = "⌬ ",
            key = "f",
            desc = "Find File",
            action = function() Snacks.picker.files() end,
          },
          {
            icon = "∿ ",
            key = "s",
            desc = "Find Word",
            action = function() Snacks.picker.grep() end,
          },
          {
            icon = "↺ ",
            key = "r",
            desc = "Recent Files",
            action = function() Snacks.picker.recent() end,
          },
          { icon = "⟳ ", key = "R", desc = "Restore Session", action = "<cmd>SessionRestore<CR>" },
          { icon = "⊗ ", key = "q", desc = "Quit",            action = ":qa" },
        },
      },
    },
  },

  -- ══════════════════════════════════════════════════════════════════════
  -- Keys (lazy.nvim top-level, NOT inside opts)
  -- ══════════════════════════════════════════════════════════════════════
  keys = {
    -- ── File explorer ──────────────────────────────────────────────────
    {
      "<leader>ee",
      function()
        Snacks.explorer()
      end,
      desc = "File explorer",
    },

    -- ── Picker Search (Fuzzy Finder) ───────────────────────────────────
    { "<leader><space>", function() Snacks.picker.files() end, desc = "Find files" },
    { "<leader>ff", function() Snacks.picker.files() end, desc = "Find files" },
    { "<leader>fg", function() Snacks.picker.git_files() end, desc = "Find git files" },
    { "<leader>fr", function() Snacks.picker.recent() end, desc = "Recent files" },
    { "<leader>fb", function() Snacks.picker.buffers() end, desc = "Find buffers" },
    { "<leader>fs", function() Snacks.picker.grep() end, desc = "Grep string (workspace)" },
    { "<leader>fw", function() Snacks.picker.grep_word() end, desc = "Grep word under cursor" },
    { "<leader>fc", function() Snacks.picker.grep_word() end, desc = "Grep word under cursor (compat)" },
    { "<leader>fd", function() Snacks.picker.diagnostics() end, desc = "Find workspace diagnostics" },
    { "<leader>fh", function() Snacks.picker.help() end, desc = "Find help pages" },
    { "<leader>fk", function() Snacks.picker.keymaps() end, desc = "Find keymaps" },
    { "<leader>ft", function() Snacks.picker.todo_comments() end, desc = "Find todos" },
    { "<leader>f/", function() Snacks.picker.lines() end, desc = "Fuzzy find in current buffer" },
    { "<leader>f\"", function() Snacks.picker.registers() end, desc = "Find registers" },
    { "<leader>f:", function() Snacks.picker.command_history() end, desc = "Command history" },
    { "<leader>fR", function() Snacks.picker.resume() end, desc = "Resume last search" },

    -- ── LSP pickers ──────────────────────────────────────────────────
    {
      "gR",
      function()
        Snacks.picker.lsp_references()
      end,
      desc = "LSP references",
    },
    {
      "gd",
      function()
        Snacks.picker.lsp_definitions()
      end,
      desc = "LSP definitions",
    },
    {
      "gi",
      function()
        Snacks.picker.lsp_implementations()
      end,
      desc = "LSP implementations",
    },
    {
      "gt",
      function()
        Snacks.picker.lsp_type_definitions()
      end,
      desc = "LSP type definitions",
    },
    {
      "<leader>D",
      function()
        Snacks.picker.diagnostics_buffer()
      end,
      desc = "Buffer diagnostics",
    },

    -- ── LazyGit ──────────────────────────────────────────────────────
    {
      "<leader>gg",
      function()
        Snacks.lazygit()
      end,
      desc = "Open LazyGit",
    },
    {
      "<leader>gl",
      function()
        Snacks.lazygit.log()
      end,
      desc = "LazyGit Log",
    },

    -- ── Notifications ────────────────────────────────────────────────
    {
      "<leader>nh",
      function()
        Snacks.notifier.show_history()
      end,
      desc = "Notification history",
    },
    {
      "<leader>nd",
      function()
        Snacks.notifier.hide()
      end,
      desc = "Dismiss notifications",
    },

    -- ── Words: jump between LSP references ───────────────────────────
    {
      "]]",
      function()
        Snacks.words.jump(1)
      end,
      desc = "Next word reference",
    },
    {
      "[[",
      function()
        Snacks.words.jump(-1)
      end,
      desc = "Prev word reference",
    },

    -- ── Terminal ─────────────────────────────────────────────────────
    {
      "<C-/>",
      function()
        Snacks.terminal()
      end,
      mode = { "n", "t" },
      desc = "Toggle terminal",
    },
    {
      "<C-_>",
      function()
        Snacks.terminal()
      end,
      mode = { "n", "t" },
      desc = "Toggle terminal (which-key compat)",
    },
    {
      "jk",
      "<C-\\><C-n>",
      mode = "t",
      desc = "Exit terminal mode",
    },

    -- ── UI Toggles & Zen Mode ───────────────────────────────────────
    { "<leader>ul", function() Snacks.toggle.line_number():toggle() end, desc = "Toggle Line Numbers" },
    { "<leader>uL", function() Snacks.toggle.relativenumber():toggle() end, desc = "Toggle Relative Numbers" },
    { "<leader>uw", function() Snacks.toggle.option("wrap", { name = "Wrap" }):toggle() end, desc = "Toggle Wrap" },
    { "<leader>ud", function() Snacks.toggle.diagnostics():toggle() end, desc = "Toggle Diagnostics" },
    { "<leader>uh", function() Snacks.toggle.inlay_hints():toggle() end, desc = "Toggle Inlay Hints" },
    { "<leader>I", function() Snacks.toggle.indent():toggle() end, desc = "Toggle Indent Guides" },
    {
      "<leader>uz",
      function()
        Snacks.zen()
      end,
      desc = "Zen mode toggle",
    },
    {
      "<leader>sm",
      function()
        Snacks.zen.zoom()
      end,
      desc = "Maximize/minimize split (zoom)",
    },

    -- ── Scratch buffers ─────────────────────────────────────────────
    {
      "<leader>.",
      function()
        Snacks.scratch()
      end,
      desc = "Toggle scratch buffer",
    },
    {
      "<leader>S",
      function()
        Snacks.scratch.select()
      end,
      desc = "Select scratch buffer",
    },

    -- ── Git browse ──────────────────────────────────────────────────
    {
      "<leader>gB",
      function()
        Snacks.gitbrowse()
      end,
      desc = "Open in browser (GitHub)",
    },

    -- ── Git blame ───────────────────────────────────────────────────
    {
      "<leader>gb",
      function()
        Snacks.git.blame_line()
      end,
      desc = "Git blame line",
    },

    -- ── Buffer delete ───────────────────────────────────────────────
    {
      "<leader>bd",
      function()
        Snacks.bufdelete()
      end,
      desc = "Delete buffer",
    },
    {
      "<leader>bo",
      function()
        Snacks.bufdelete.other()
      end,
      desc = "Delete other buffers",
    },
  },
}
