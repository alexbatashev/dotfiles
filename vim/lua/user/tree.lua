vim.cmd([[ let g:neo_tree_remove_legacy_commands = 1 ]])

require("neo-tree").setup({
    close_if_last_window = true,
})

require("user.remap").nnoremap("<leader>tv", "<cmd>Neotree<CR>")
