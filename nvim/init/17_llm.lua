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
