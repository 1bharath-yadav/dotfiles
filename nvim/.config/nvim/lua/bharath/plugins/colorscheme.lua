return {
  -- Tokyo Night theme
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      local transparent = true -- Set to true if you want a transparent background

      require("tokyonight").setup({
        style = "night", -- Options: "storm", "night", "moon", "day"

        transparent = transparent,
      })

      -- Uncomment to use Tokyo Night as the default colorscheme
      --vim.cmd("colorscheme tokyonight")
    end,
  },

  -- Catppuccin theme
  {
    "catppuccin/nvim",
    name = "catppuccin", -- Set the plugin name
    lazy = false, -- Load on startup
    priority = 1000, -- Ensure it loads first
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- Options: "latte", "frappe", "macchiato", "mocha"
        transparent_background = true,
        integrations = {
          treesitter = true,
          lsp_trouble = true,
          which_key = true,
          gitsigns = true,
          telescope = true,
        },
      })

      -- Uncomment to use Catppuccin as the default colorscheme
      vim.cmd([[colorscheme catppuccin-macchiato]])
    end,
  },

  -- Gruvbox theme
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      require("gruvbox").setup({
        contrast = "hard", -- Options: "soft", "medium", "hard"
        transparent_mode = true, -- Enable transparent background
      })

      -- Uncomment to use Gruvbox as the default colorscheme
      -- vim.cmd([[colorscheme gruvbox]])
    end,
  },
}
