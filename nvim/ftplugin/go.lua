vim.bo.expandtab = false

pcall(vim.treesitter.start)
vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'

local bufnr = vim.api.nvim_get_current_buf()
local nmap = function(suffix, rhs, desc)
  vim.keymap.set('n', '<Leader>l' .. suffix, rhs, { buffer = bufnr, desc = desc })
end

-- generic LSP actions stay on the global <Leader>l maps, these are go-specific
nmap('t', vim.cmd.GoTest, 'Test package')
nmap('T', vim.cmd.GoTestFunc, 'Test function')
nmap('c', vim.cmd.GoCoverage, 'Coverage')
nmap('e', vim.cmd.GoIfErr, 'Add if err')
nmap('F', vim.cmd.GoFillStruct, 'Fill struct')
nmap('w', vim.cmd.GoFillSwitch, 'Fill switch')
nmap('g', vim.cmd.GoGenReturn, 'Generate return')
nmap('I', vim.cmd.GoImpl, 'Implement interface')
nmap('m', vim.cmd.GoModTidy, 'Mod tidy')
nmap('A', vim.cmd.GoAlt, 'Alternate file')
nmap('k', vim.cmd.GoDoc, 'Doc')
nmap('j', vim.cmd.GoAddTag, 'Add tags')
nmap('J', vim.cmd.GoRmTag, 'Remove tags')
nmap('o', vim.cmd.GoPkgOutline, 'Package outline')
nmap('v', vim.cmd.GoVulnCheck, 'Vulnerability check')
