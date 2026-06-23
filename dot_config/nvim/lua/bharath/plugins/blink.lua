-- blink.lua — blink.cmp completion + copilot-lua
-- Replaces: github/copilot.vim + hrsh7th/nvim-cmp stack

return {
  -- ── Copilot (lua backend, no VimScript) ──────────────────────────────────
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    opts = {
      suggestion = { enabled = false }, -- blink.cmp handles suggestions
      panel = { enabled = false },
      filetypes = { markdown = true, help = false },
    },
  },

  -- ── blink.cmp — fast completion engine ───────────────────────────────────
  {
    "saghen/blink.cmp",
    event = "InsertEnter",
    version = "1.*", -- use release tags for prebuilt binaries
    dependencies = {
      "rafamadriz/friendly-snippets",
      -- copilot source via blink-compat shim
      {
        "giuxtaposition/blink-cmp-copilot",
        dependencies = { "zbirenbaum/copilot.lua" },
      },
    },
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "default",
        -- match old nvim-cmp muscle memory
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-b>"] = { "scroll_documentation_up", "fallback" },
        ["<C-f>"] = { "scroll_documentation_down", "fallback" },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },

      appearance = {
        use_nvim_cmp_as_default = false,
        nerd_font_variant = "mono",
      },

      completion = {
        accept = { auto_brackets = { enabled = true } },
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        ghost_text = { enabled = true }, -- inline copilot-style preview
        menu = {
          draw = {
            treesitter = { "lsp" },
            columns = { { "label", "label_description", gap = 1 }, { "kind_icon", "kind" } },
          },
        },
      },

      sources = {
        default = { "lsp", "path", "snippets", "buffer", "copilot" },
        -- obsidian.nvim now provides completions via its built-in LSP,
        -- so no per_filetype override is needed for markdown
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            score_offset = 100, -- float copilot to top
            async = true,
          },
        },
      },

      snippets = { preset = "luasnip" }, -- reuse existing LuaSnip snippets

      signature = { enabled = true }, -- show fn signature while typing

      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },

  -- ── Keep LuaSnip for snippet authoring (markdown.lua etc.) ───────────────
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
