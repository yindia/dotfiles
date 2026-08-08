vim.treesitter.start()
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

if vim.fs.basename(vim.api.nvim_buf_get_name(0)) ~= 'Cargo.toml' then return end

local crates = require('crates')
local bufnr = vim.api.nvim_get_current_buf()
local nmap = function(suffix, rhs, desc)
  vim.keymap.set('n', '<Leader>l' .. suffix, rhs, { buffer = bufnr, desc = desc })
end

nmap('h', crates.show_popup, 'Crate details')
nmap('v', crates.show_versions_popup, 'Versions')
nmap('f', crates.show_features_popup, 'Features')
nmap('D', crates.show_dependencies_popup, 'Dependencies')
nmap('u', crates.update_crate, 'Update crate')
nmap('U', crates.upgrade_crate, 'Upgrade crate')
nmap('A', crates.upgrade_all_crates, 'Upgrade all crates')
nmap('o', crates.open_documentation, 'Open docs')
nmap('R', crates.open_repository, 'Open repository')
