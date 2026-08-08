pcall(vim.treesitter.start)
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

local bufnr = vim.api.nvim_get_current_buf()
local nmap = function(suffix, rhs, desc)
  vim.keymap.set('n', '<Leader>l' .. suffix, rhs, { buffer = bufnr, desc = desc })
end
local xmap = function(suffix, rhs, desc)
  vim.keymap.set('x', '<Leader>l' .. suffix, rhs, { buffer = bufnr, desc = desc })
end

nmap('a', function() vim.cmd.RustLsp('codeAction') end, 'Actions')
xmap('a', function() vim.cmd.RustLsp('codeAction') end, 'Actions')
nmap('h', function() vim.cmd.RustLsp({ 'hover', 'actions' }) end, 'Hover actions')
nmap('e', function() vim.cmd.RustLsp('explainError') end, 'Explain error')
nmap('d', function() vim.cmd.RustLsp('renderDiagnostic') end, 'Render diagnostic')
nmap('m', function() vim.cmd.RustLsp('expandMacro') end, 'Expand macro')
nmap('o', function() vim.cmd.RustLsp('openCargo') end, 'Open Cargo.toml')
nmap('r', function() vim.cmd.RustLsp('runnables') end, 'Runnables')
nmap('t', function() vim.cmd.RustLsp('testables') end, 'Testables')
