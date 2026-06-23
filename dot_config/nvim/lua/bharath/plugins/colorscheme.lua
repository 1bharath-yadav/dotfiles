return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    priority = 1000,
    opts = {
      style = "night",
      transparent = true,
    },
    config = function(_, opts)
      require("tokyonight").setup({
        style = opts.style,
        transparent = opts.transparent,
      })
    end,
  },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      custom_highlights = function()
        return {
          NormalSB = { bg = "NONE" },
          NormalFloat = { bg = "NONE" },
        }
      end,
      integrations = {
        treesitter = true,
        lsp_trouble = true,
        which_key = true,
        gitsigns = true,
        snacks = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd([[colorscheme catppuccin-macchiato]])
    end,
  },

  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    priority = 1000,
    opts = {
      contrast = "hard",
      transparent_mode = true,
    },
  },
}
