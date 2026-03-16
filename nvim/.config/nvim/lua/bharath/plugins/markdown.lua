-- markdown.lua — Power-user markdown & note-taking setup
-- Features: render, preview, wiki-links, tables, zen, image-paste, snippets, outline

return {

  -- ── 1. Inline rendering (headings, code blocks, checkboxes, tables) ───────
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown", "md", "mdx" },
    opts = {
      heading = {
        enabled = true,
        sign = false,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
      bullet = { enabled = true },
      checkbox = {
        enabled = true,
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 " },
      },
      code = { enabled = true, sign = false, width = "block", left_pad = 2 },
      dash = { enabled = true },
      table = { enabled = true },
      link = { enabled = true },
      -- Only render in normal mode; raw markdown visible in insert mode
      render_modes = { "n", "c" },
    },
  },

  -- ── 2. Live browser preview ───────────────────────────────────────────────
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown preview toggle" },
    },
    config = function()
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_theme = "dark"
    end,
  },

  -- ── 3. Obsidian vault: wiki-links, backlinks, tags, daily notes ───────────
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    lazy = true,
    ft = "markdown",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "hrsh7th/nvim-cmp",
    },
    opts = {
      workspaces = { { name = "notes", path = "/home/archer/Sync/obsidian_vault/lifey" } }, -- ← change to your vault
      daily_notes = { folder = "daily", template = "daily.md" },
      completion = { nvim_cmp = true, min_chars = 2 },
      new_notes_location = "current_dir",
      wiki_link_func = "use_alias_only",
      follow_url_func = function(url)
        vim.fn.jobstart({ "xdg-open", url })
      end,
      ui = { enable = false }, -- render-markdown.nvim handles visuals
    },
    keys = {
      { "<leader>on", "<cmd>ObsidianNew<cr>", desc = "New note" },
      { "<leader>oo", "<cmd>ObsidianOpen<cr>", desc = "Open in Obsidian app" },
      { "<leader>os", "<cmd>ObsidianSearch<cr>", desc = "Search notes" },
      { "<leader>oq", "<cmd>ObsidianQuickSwitch<cr>", desc = "Quick switch note" },
      { "<leader>ob", "<cmd>ObsidianBacklinks<cr>", desc = "Backlinks" },
      { "<leader>ot", "<cmd>ObsidianTags<cr>", desc = "Browse tags" },
      { "<leader>od", "<cmd>ObsidianToday<cr>", desc = "Today's daily note" },
      { "<leader>oy", "<cmd>ObsidianYesterday<cr>", desc = "Yesterday's daily note" },
      { "<leader>ol", "<cmd>ObsidianLink<cr>", mode = "v", desc = "Link selection" },
      { "<leader>oL", "<cmd>ObsidianLinkNew<cr>", mode = "v", desc = "Link → new note" },
      { "<leader>oe", "<cmd>ObsidianExtractNote<cr>", mode = "v", desc = "Extract → note" },
      { "<leader>op", "<cmd>ObsidianPasteImg<cr>", desc = "Paste image" },
      { "<leader>or", "<cmd>ObsidianRename<cr>", desc = "Rename + update links" },
      { "<leader>oc", "<cmd>ObsidianToggleCheckbox<cr>", desc = "Toggle checkbox" },
      { "<leader>oT", "<cmd>ObsidianTemplate<cr>", desc = "Insert template" },
    },
  },

  -- ── 4. Zen / focus writing mode ──────────────────────────────────────────
  {
    "folke/zen-mode.nvim",
    cmd = "ZenMode",
    dependencies = { "folke/twilight.nvim" },
    keys = {
      { "<leader>mz", "<cmd>ZenMode<cr>", desc = "Zen mode toggle" },
    },
    opts = {
      window = { width = 90, options = { signcolumn = "no", number = false } },
      plugins = { twilight = { enabled = true }, gitsigns = { enabled = false } },
    },
  },

  -- ── 5. Dim unfocused paragraphs ───────────────────────────────────────────
  {
    "folke/twilight.nvim",
    cmd = { "Twilight", "TwilightEnable", "TwilightDisable" },
    opts = { dimming = { alpha = 0.25 }, context = 15 },
  },

  -- ── 6. Auto-aligned tables ────────────────────────────────────────────────
  {
    "dhruvasagar/vim-table-mode",
    ft = "markdown",
    keys = {
      { "<leader>mt", "<cmd>TableModeToggle<cr>", desc = "Table mode toggle" },
      { "<leader>mf", "<cmd>TableModeRealign<cr>", desc = "Realign table" },
    },
    config = function()
      vim.g.table_mode_corner = "|"
    end,
  },

  -- ── 7. Paste clipboard images → assets/timestamp.png ─────────────────────
  {
    "HakonHarnes/img-clip.nvim",
    event = "BufEnter",
    ft = "markdown",
    opts = {
      default = {
        dir_path = "assets",
        file_name = "%Y%m%d_%H%M%S",
        use_absolute_path = false,
        relative_to_current_file = true,
        prompt_for_file_name = false,
      },
    },
    keys = {
      { "<leader>mi", "<cmd>PasteImage<cr>", desc = "Paste image from clipboard" },
    },
  },

  -- ── 8. Smart list continuation & checkbox cycling ─────────────────────────
  {
    "dkarter/bullets.vim",
    ft = "markdown",
    config = function()
      vim.g.bullets_enabled_file_types = { "markdown", "text" }
      vim.g.bullets_checkbox_markers = " .oOX"
    end,
  },

  -- ── 9. Outline / TOC panel + heading jumps ────────────────────────────────
  {
    "stevearc/aerial.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<leader>mo", "<cmd>AerialToggle!<cr>", desc = "Outline / TOC toggle" },
      { "[h", "<cmd>AerialPrev<cr>", desc = "Prev heading" },
      { "]h", "<cmd>AerialNext<cr>", desc = "Next heading" },
    },
    opts = {
      backends = { "treesitter", "markdown" },
      layout = { max_width = { 40, 0.3 }, default_direction = "right" },
    },
  },

  -- ── 10. LuaSnip snippets for markdown ─────────────────────────────────────
  {
    "L3MON4D3/LuaSnip",
    ft = "markdown",
    config = function()
      local ls = require("luasnip")
      local s, t, i, f = ls.snippet, ls.text_node, ls.insert_node, ls.function_node
      local date = function()
        return { os.date("%Y-%m-%d") }
      end

      ls.add_snippets("markdown", {
        -- YAML front-matter
        s("fm", {
          t({ "---", "title: " }),
          i(1, "Title"),
          t({ "", "date: " }),
          f(date, {}),
          t({ "", "tags: [" }),
          i(2),
          t({ "]", "---", "" }),
          i(0),
        }),
        -- Fenced code block
        s("cb", { t("```"), i(1, "lang"), t({ "", "" }), i(2), t({ "", "```", "" }) }),
        -- Task item
        s("task", { t("- [ ] "), i(1) }),
        -- Obsidian callout
        s("call", { t("> [!"), i(1, "NOTE"), t({ "]", "> " }), i(2) }),
      })
    end,
  },

  -- ── 11. Word count in lualine status bar ──────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      local function word_count()
        if vim.bo.filetype == "markdown" then
          return "  " .. tostring(vim.fn.wordcount().words) .. "w"
        end
        return ""
      end
      opts.sections = opts.sections or {}
      opts.sections.lualine_x = opts.sections.lualine_x or {}
      table.insert(opts.sections.lualine_x, 1, word_count)
      return opts
    end,
  },

  -- ── 12. FileType-level writing options ────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    config = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
          local o = vim.opt_local
          o.wrap = true
          o.linebreak = true -- break at word boundaries, not mid-word
          o.spell = true
          o.spelllang = "en_us"
          o.conceallevel = 2 -- required for render-markdown.nvim
          o.formatoptions:append("jro")
          -- Move by visual line when text is wrapped
          vim.keymap.set("n", "j", "gj", { buffer = true, silent = true })
          vim.keymap.set("n", "k", "gk", { buffer = true, silent = true })
        end,
      })
    end,
  },
}
