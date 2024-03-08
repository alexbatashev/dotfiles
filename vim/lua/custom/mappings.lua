---@type MappingsTable
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },

    --  format with conform
    ["<leader>fm"] = {
      function()
        require("conform").format()
      end,
      "formatting",
    },

    ["<C-p>"] = {
      "<cmd> Telescope git_files <CR>",
      "show git files",
      opts = { nowait = true }
    },

    ["<C-g>"] = {
      "<cmd> Telescope grep_string <CR>",
      "search in project",
      opts = { nowait = true }
    },

    ["<C-f>"] = {
      "<cmd> Telescope find_files <CR>",
      "search for all files (noisy)",
      opts = { nowait = true }
    },

    ["<C-b>"] = {
      "<cmd> Telescope buffers <CR>",
      "show open buffers",
      opts = { nowait = true }
    }

  },
  v = {
    [">"] = { ">gv", "indent"},
  },
}

-- more keybinds!

return M
