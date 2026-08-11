vim.wo.spell = true
vim.wo.wrap = true

vim.treesitter.start()
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

-- markdown-preview only defines its commands in the buffers it recognises, so
-- the toggle is mapped here rather than alongside the global ones
vim.keymap.set(
  'n',
  '<Leader>tp',
  vim.cmd.MarkdownPreviewToggle,
  { buffer = true, desc = 'Markdown browser preview' }
)
