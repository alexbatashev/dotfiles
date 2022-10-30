require("luasnip").setup({
    region_check_events = "InsertEnter",
    delete_check_events = "InsertLeave",
})
require("luasnip.loaders.from_vscode").lazy_load()
