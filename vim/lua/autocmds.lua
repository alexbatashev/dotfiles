local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd
local cmd = vim.api.nvim_create_user_command
local namespace = vim.api.nvim_create_namespace

autocmd("FileType", {
  pattern = { "gitcommit", "markdown", "text", "plaintex", "tex", "latex" },
  group = augroup("auto_spell", { clear = true }),
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})

autocmd("TextYankPost", {
  desc = "Highlight yanked text",
  group = augroup("highlightyank", { clear = true }),
  pattern = "*",
  callback = function() vim.highlight.on_yank() end,
})

augroup("DiagnosticMode", { clear = true })
autocmd("ModeChanged", {
  pattern = { "i", "v" },
  group = "DiagnosticMode",
  callback = function()
    if vim.lsp.buf.server_ready() then vim.diagnostic.hide() end
  end,
})

autocmd("ModeChanged", {
  pattern = "n",
  group = "DiagnosticMode",
  callback = function()
    if vim.lsp.buf.server_ready() then vim.diagnostic.show() end
  end,
})
