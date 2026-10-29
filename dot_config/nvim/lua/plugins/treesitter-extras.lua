-- Add only HTML/JSX auto-tagging; LazyVim already manages Tree-sitter itself.
return {
  { "windwp/nvim-ts-autotag", event = { "BufReadPre", "BufNewFile" }, opts = {} },
  {
    "nvim-treesitter/nvim-treesitter-textobjects",
    lazy = true,
    opts = {
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ["af"] = "@function.outer", ["if"] = "@function.inner",
            ["ac"] = "@class.outer", ["ic"] = "@class.inner",
            ["aa"] = "@parameter.outer", ["ia"] = "@parameter.inner",
          },
        },
      },
    },
  },
}
