return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  config = function()
    local treesitter = require("nvim-treesitter.configs")

    local function first_node(match, capture)
      local node = match[capture]
      return type(node) == "table" and node[1] or node
    end

    local function install_query_compat()
      local query = require("vim.treesitter.query")
      local opts = { force = true, all = false }
      local aliases = { ex = "elixir", pl = "perl", sh = "bash", ts = "typescript", uxn = "uxntal" }
      local mimetypes = {
        importmap = "json",
        module = "javascript",
        ["application/ecmascript"] = "javascript",
        ["text/ecmascript"] = "javascript",
      }

      query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
        local node = first_node(match, pred[2])
        if not node then
          return
        end

        local lang = vim.treesitter.get_node_text(node, bufnr):lower()
        metadata["injection.language"] = vim.filetype.match({ filename = "x." .. lang }) or aliases[lang] or lang
      end, opts)

      query.add_directive("set-lang-from-mimetype!", function(match, _, bufnr, pred, metadata)
        local node = first_node(match, pred[2])
        if not node then
          return
        end

        local mimetype = vim.treesitter.get_node_text(node, bufnr)
        local parts = vim.split(mimetype, "/", {})
        metadata["injection.language"] = mimetypes[mimetype] or parts[#parts]
      end, opts)
    end

    install_query_compat()

    treesitter.setup({
      highlight = {
        enable = true,
      },
      indent = { enable = true },
      ensure_installed = {
        "bash",
        "c",
        "css",
        "dockerfile",
        "gitignore",
        "graphql",
        "html",
        "json",
        "javascript",
        "lua",
        "markdown",
        "markdown_inline",
        "prisma",
        "query",
        "svelte",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    })

    vim.treesitter.language.register("bash", "zsh")
  end,
}
