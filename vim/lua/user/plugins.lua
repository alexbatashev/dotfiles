local install_path = vim.fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
local is_bootstrap = false
if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
	is_bootstrap = true
	vim.fn.execute("!git clone https://github.com/wbthomason/packer.nvim " .. install_path)
	vim.cmd([[packadd packer.nvim]])
end

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
	return
end

packer.init({
	autoremove = true,
})

packer.startup(function(use)
	use("wbthomason/packer.nvim") -- Have packer manage itself

	use {
		'neovim/nvim-lspconfig', -- Configurations for Nvim LSP
		config = function()
			require("user.lsp")
		end,
	}
	use("kabouzeid/nvim-lspinstall")
	use {'ms-jpq/coq_nvim', branch = 'coq'}
        use {'ms-jpq/coq.artifacts', branch = 'artifacts'}

        use {
            'ms-jpq/coq.thirdparty',
            requires = {'ms-jpq/coq_nvim'},
            config = function()
                require("coq_3p") {
                    {src = "nvimlua", short_name = "nLUA"},
                    {src = "copilot", short_name = "COP", accept_key = "<c-f>"}
                }
            end
        }

	-- Temporarily disable until I figure out how to config this thing
	-- use 'simrat39/rust-tools.nvim'
        use 'p00f/clangd_extensions.nvim'

        use { "sitiom/nvim-numbertoggle" }

	use {
		"nvim-neo-tree/neo-tree.nvim",
		  branch = "v2.x",
		  requires = { 
			"nvim-lua/plenary.nvim",
			"kyazdani42/nvim-web-devicons", -- not strictly required, but recommended
			"MunifTanjim/nui.nvim",
		  },
		  config = function()
			require("user.tree")
		  end,
	}

	use {
	  'akinsho/bufferline.nvim',
	  tag = "v3.*",
	  requires = 'kyazdani42/nvim-web-devicons',
	  config = function()
	    require("user.bufferline")
	  end,
	}

	use {
		'nvim-lualine/lualine.nvim',
		requires = { 'kyazdani42/nvim-web-devicons', opt = true },
		config = function()
			require("user.lualine")
		end,
	}

	use {
		'lewis6991/gitsigns.nvim',
		config = function()
			require('gitsigns').setup()
		end,
	}

	use {
		"akinsho/toggleterm.nvim",
		config = function()
			require("user.toggleterm")
	  	end
	}

        use 'nvim-lua/plenary.nvim'

	use {
	  "mfussenegger/nvim-dap",
	  config = function()
	    require("user.dap")
	  end
	}

	use({
		"nvim-treesitter/nvim-treesitter",
		run = ":TSUpdate",
		config = function()
			require("user.treesitter")
		end,
		requires = {
			"nvim-treesitter/nvim-treesitter-textobjects",
			"nvim-treesitter/nvim-treesitter-context",
		},
	})

	use {
		'nvim-telescope/telescope.nvim', branch = '0.1.x',
		requires = { {'nvim-lua/plenary.nvim'} },
		config = function()
			require("user.telescope")
		end,
	}

        use {
	  "windwp/nvim-autopairs",
          config = function()
            require("nvim-autopairs").setup {}
          end
        }

	use({
		"Pocco81/auto-save.nvim",
		config = function()
			require("auto-save").setup({
				trigger_events = {
					"FocusLost",
				},
				write_all_buffers = true,
			})
		end,
	})

	-- Automatically set up your configuration after cloning packer.nvim
	-- Put this at the end after all plugins
	if is_bootstrap then
		packer.sync()
	end
end)

if is_bootstrap then
	print("==================================")
	print("    Plugins are being installed")
	print("    Wait until Packer completes,")
	print("       then restart nvim")
	print("==================================")
	return
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.api.nvim_create_autocmd("BufWritePost", {
	command = "source <afile> | PackerSync",
	group = vim.api.nvim_create_augroup("Packer", { clear = true }),
	pattern = "plugins.lua",
})
