-- Personal Markdown workflow: rendering, preview, Obsidian notes, tables,
-- image pasting, bullets, and an outline. LazyVim's Markdown extras should
-- be enabled only if they do not duplicate these explicit integrations.
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ft = { "markdown", "md", "mdx" },
    opts = {
      heading = { enabled = true, sign = false, icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " } },
      bullet = { enabled = true },
      checkbox = { enabled = true, unchecked = { icon = "󰄱 " }, checked = { icon = "󰱒 " } },
      code = { enabled = true, sign = false, width = "block", left_pad = 2 },
      dash = { enabled = true },
      table = { enabled = true },
      link = { enabled = true },
      render_modes = { "n", "c" },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = "cd app && npm install",
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown preview" },
    },
    config = function()
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_combine_preview = 1
      vim.g.mkdp_combine_preview_auto_refresh = 1
    end,
  },
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*",
    ft = "markdown",
    cmd = { "Obsidian" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      workspaces = { { name = "til", path = "/home/archer/til" } },
      daily_notes = {
        folder = nil,
        date_format = "%Y/%m/journals/%Y-%m-%d_journal",
        alias_format = "%B %-d, %Y",
        default_tags = { "daily", "journal" },
      },
      new_notes_location = "current_dir",
      link = { style = "wiki" },
      legacy_commands = false,
      picker = { name = "snacks.picker" },
      ui = { enable = false }, -- render-markdown.nvim handles UI rendering
    },
    keys = {
      { "<leader>on", "<cmd>Obsidian new<CR>", desc = "New Obsidian note" },
      { "<leader>oo", "<cmd>Obsidian open<CR>", desc = "Open in Obsidian app" },
      { "<leader>os", "<cmd>Obsidian search<CR>", desc = "Search Obsidian notes" },
      { "<leader>oq", "<cmd>Obsidian quick_switch<CR>", desc = "Quick switch note" },
      { "<leader>ot", "<cmd>Obsidian today<CR>", desc = "Today's daily note" },
      { "<leader>oy", "<cmd>Obsidian yesterday<CR>", desc = "Yesterday's daily note" },
      { "<leader>od", "<cmd>Obsidian dailies<CR>", desc = "Daily notes picker" },
      {
        "<leader>ow",
        function()
          local vault = "/home/archer/til"
          local year = os.date("%Y")
          local week = tostring(tonumber(os.date("%V")))
          local path = string.format("%s/%s/weekly/week%s_journel.md", vault, year, week)
          local dir = vim.fs.dirname(path)
          if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, "p")
          end
          if vim.fn.filereadable(path) == 0 then
            local now = os.time()
            local wday = tonumber(os.date("%u", now))
            local mon_t = now - (wday - 1) * 86400
            local sun_t = mon_t + 6 * 86400
            local dates = string.format(
              "%d %s – %d %s %s",
              tonumber(os.date("%d", mon_t)),
              os.date("%b", mon_t),
              tonumber(os.date("%d", sun_t)),
              os.date("%b", sun_t),
              os.date("%Y", sun_t)
            )
            local lines = {
              "---",
              string.format("week: %s-W%s", year, os.date("%V", now)),
              string.format("dates: %s", dates),
              "tags: [weekly_review]",
              "---",
              "",
              "## ⚡ Week Pulse",
              "> ",
              "",
              "## 🏆 Wins",
              "- ",
              "",
              "## 🔥 Friction",
              "- ",
              "",
              "## 💡 Insights",
              "- ",
              "",
              "## 📌 Carried Forward",
              "- [ ] ",
              "",
              "## 🔗 Significant Days",
              "",
            }
            vim.fn.writefile(lines, path)
          end
          vim.cmd.edit(path)
        end,
        desc = "This week's review note",
      },
    },
  },
  {
    "dhruvasagar/vim-table-mode",
    ft = "markdown",
    keys = { { "<leader>mt", "<cmd>TableModeToggle<CR>", desc = "Toggle Markdown table mode" } },
  },
  {
    "HakonHarnes/img-clip.nvim",
    cmd = "PasteImage",
    ft = "markdown",
    opts = { default = { dir_path = "assets", file_name = "%Y%m%d_%H%M%S", use_absolute_path = false, relative_to_current_file = true, prompt_for_file_name = false } },
    keys = { { "<leader>mi", "<cmd>PasteImage<CR>", desc = "Paste image into Markdown" } },
  },
  { "dkarter/bullets.vim", ft = "markdown" },
  {
    "stevearc/aerial.nvim",
    ft = "markdown",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    keys = { { "<leader>mo", "<cmd>AerialToggle!<CR>", desc = "Toggle Markdown outline" } },
    opts = { backends = { "treesitter", "markdown" }, layout = { max_width = { 40, 0.3 }, default_direction = "right" } },
  },
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = { "rafamadriz/friendly-snippets" },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
}
