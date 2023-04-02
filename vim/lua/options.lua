vim.opt.backspace = vim.opt.backspace + { "nostop" } -- Don't stop backspace at insert
vim.opt.clipboard = "unnamedplus" -- Connection to the system clipboard
vim.opt.cmdheight = 0 -- hide command line unless needed
vim.opt.completeopt = { "menuone", "noselect" } -- Options for insert mode completion
vim.opt.copyindent = true -- Copy the previous indentation on autoindenting
vim.opt.cursorline = true -- Highlight the text line of the cursor
vim.opt.expandtab = true -- Enable the use of space in tab
vim.opt.fileencoding = "utf-8" -- File content encoding for the buffer
vim.opt.fillchars = { eob = " " } -- Disable `~` on nonexistent lines
vim.opt.history = 100 -- Number of commands to remember in a history table
vim.opt.ignorecase = true
vim.opt.lazyredraw = true
vim.opt.number = true
vim.opt.scrolloff = 8
vim.opt.shiftwidth = 2
vim.opt.smartcase = true
vim.opt.mouse = ""
-- TODO figure out why this does not work for tmux
-- vim.opt.termguicolors = true
vim.opt.undofile = true
vim.opt.wrap = false

vim.cmd([[au! BufRead,BufNewFile *.ll     set filetype=llvm]])
vim.cmd([[au! BufRead,BufNewFile *.td     set filetype=tablegen]])
vim.cmd([[au! BufRead,BufNewFile *.rst    set filetype=rest]])
vim.cmd([[au! BufRead,BufNewFile *.mlir   set filetype=mlir]])

vim.keymap.set('n', '<C-h>', 'zh', silent) -- left
vim.keymap.set('n', '<C-l>', 'zl', silent) -- right

-- smart deletion, dd
-- It solves the issue, where you want to delete empty line, but dd will override you last yank.
-- Code below will check if u are deleting empty line, if so - use black hole register.
-- [src: https://www.reddit.com/r/neovim/comments/w0jzzv/comment/igfjx5y/?utm_source=share&utm_medium=web2x&context=3]
local function smart_dd()
	if vim.api.nvim_get_current_line():match("^%s*$") then
		return "\"_dd"
	else return "dd" end
end
vim.keymap.set("n", "dd", smart_dd, { noremap = true, expr = true })
