require("toggleterm").setup{
    -- size can be a number or function which is passed the current terminal
    size = 20,
    direction = "float",
    shading_factor = 2,
    open_mapping = [[<F7>]],
    float_opts = {
        border = "curved",
        highlights = {
          border = "Normal",
          background = "Normal",
        },
    },
}
