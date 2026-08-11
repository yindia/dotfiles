require('codecompanion').setup({
  ignore_warnings = true,
  strategies = {
    chat = {
      adapter = 'gemini_cli',
    },
    inline = {
      adapter = 'gemini_cli',
    },
    cmd = {
      adapter = 'gemini_cli',
    },
  },
  display = {
    action_palette = {
      provider = 'mini_pick',
    },
    diff = {
      provider = 'mini_diff',
    },
  },
  extensions = {
    spinner = {},
  },
})

-- opencode is configured through a global instead of a setup() call; defaults
-- are kept, so ask()/select() fall back to vim.ui.input and mini.pick, and a
-- missing server is started with `vsplit term://opencode --port`
---@type opencode.Opts
vim.g.opencode_opts = {}

-- websocket bridge to the claude CLI, terminal provider falls back to the
-- builtin one since snacks.nvim isn't installed
require('claudecode').setup({
  terminal = {
    provider = 'native',
  },
  diff_opts = {
    layout = 'vertical',
  },
})
