local dap = require('dap')

dap.adapters.lldb = {
  type = 'executable',
  command = '/usr/bin/lldb-vscode', -- adjust as needed, must be absolute path
  name = 'lldb'
}

dap.configurations.cpp = {
    name = 'Launch',
    type = 'lldb',
    request = 'launch',
    program = function()
      return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/', 'file')
    end,
    cwd = '${workspaceFolder}',
    stopOnEntry = false,
    args = {},

    -- 💀
    -- if you change `runInTerminal` to true, you might need to change the yama/ptrace_scope setting:
    --
    --    echo 0 | sudo tee /proc/sys/kernel/yama/ptrace_scope
    --
    -- Otherwise you might get the following error:
    --
    --    Error on launch: Failed to attach to the target process
    --
    -- But you should be aware of the implications:
    -- https://www.kernel.org/doc/html/latest/admin-guide/LSM/Yama.html
    -- runInTerminal = false,
}

-- If you want to use this for Rust and C, add something like this:

dap.configurations.c = dap.configurations.cpp
dap.configurations.rust = dap.configurations.cpp

vim.cmd([[nnoremap <F5> <Cmd>lua require'dap'.run(require'dap'.configurations.cpp)<CR>]])
vim.cmd([[nnoremap <F3> <Cmd>lua require'dap'.run_last()<CR>]])
vim.cmd([[nnoremap <Leader>b <Cmd>lua require'dap'.toggle_breakpoint()<CR>]])
vim.cmd([[nnoremap <Leader>B <Cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>]])
vim.cmd([[nnoremap <C-c> <Cmd>lua require'dap'.continue()<CR>]])
vim.cmd([[nnoremap <C-s> <Cmd>lua require'dap'.step_into()<CR>]])
vim.cmd([[nnoremap <Leader>s <Cmd>lua require'dap'.step_over()<CR>]])
vim.cmd([[nnoremap <Leader>S <Cmd>lua require'dap'.step_out()<CR>]])
vim.cmd([[nnoremap <Leader>dt <Cmd>lua require'dap'.repl.open()<CR>]])
