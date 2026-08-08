---@diagnostic disable-next-line: missing-fields
require('lazydev').setup({
  library = {
    { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
  },
})

require('blink.cmp').setup({
  cmdline = {
    enabled = false,
  },
  sources = {
    default = { 'lsp', 'path', 'buffer', 'snippets' },
    per_filetype = {
      codecompanion = { 'codecompanion', 'markview' },
      lua = { inherit_defaults = true, 'lazydev' },
      markdown = { 'markview' },
    },
    providers = {
      lazydev = {
        name = 'LazyDev',
        module = 'lazydev.integrations.blink',
        score_offset = 100,
      },
    },
  },
  keymap = {
    preset = 'enter',
  },
  fuzzy = {
    implementation = 'lua',
  },
  completion = {
    menu = {
      draw = {
        treesitter = { 'lsp' },
      },
    },
    list = {
      selection = {
        preselect = false,
      },
    },
    documentation = {
      auto_show = true,
    },
    trigger = {
      prefetch_on_insert = false,
    },
  },
  signature = {
    enabled = true,
    window = {
      show_documentation = false,
    },
  },
})

require('mason').setup()
require('mason-lspconfig').setup()

require('go').setup({
  -- go.nvim owns gopls, same as rustaceanvim owns rust-analyzer
  lsp_cfg = true,
  lsp_inlay_hints = {
    enable = false, -- nvim enables these natively via vim.lsp.inlay_hint
  },
  -- its defaults shadow K/gd/gr and use the deprecated vim.diagnostic.goto_*,
  -- the <Leader>l maps in 14_keymaps.lua and ftplugin/go.lua cover this instead
  lsp_keymaps = false,
  -- formatting is conform's job (see formatters_by_ft below)
  lsp_document_formatting = false,
  icons = false, -- mini.icons is already mocking nvim-web-devicons
  dap_debug = false, -- needs nvim-dap, not installed
})

-- rustaceanvim configures rust-analyzer itself, it only reads this global.
-- must be set before the first rust buffer opens, hence no setup() call.
vim.g.rustaceanvim = {
  tools = {
    float_win_config = { border = 'rounded' },
  },
  server = {
    default_settings = {
      ['rust-analyzer'] = {
        cargo = { allFeatures = true },
        checkOnSave = true,
        check = { command = 'clippy' },
      },
    },
  },
}

-- the in-process server is what feeds versions/features to blink.cmp,
-- which already takes lsp as a default source
require('crates').setup({
  lsp = {
    enabled = true,
    actions = true,
    completion = true,
    hover = true,
  },
})

require('conform').setup({
  formatters_by_ft = {
    go = { 'goimports', 'gofumpt' },
    lua = { 'stylua' },
    terraform = { 'terraform_fmt' },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_format = 'fallback',
  },
})
