return {
  "carlos-algms/agentic.nvim",
  event = "VeryLazy",

  opts = {
    provider = "codex-acp", -- use codex via ACP
  },

  keys = {
    {
      "<C-\\>",
      function()
        require("agentic").toggle()
      end,
      desc = "Agentic Toggle",
      mode = { "n", "v", "i" },
    },
  },
}
