return {
  {
    "nvim-mini/mini.nvim",
    lazy = false,
    config = function()
      require("mini.ai").setup()
      require("mini.pairs").setup()
      require("mini.surround").setup({
        mappings = {
          add = "Sr",
          replace = "Sa",
          delete = "Sd",
          find = "Sf",
          find_left = "SF",
          highlight = "Sh",
          update_n_lines = "Sn",
        },
      })
      require("mini.jump").setup()
      require("mini.icons").setup()
      require("mini.icons").mock_nvim_web_devicons()
    end,
  },
  {
    "dmtrKovalenko/fff.nvim",
    lazy = false,
    build = function() require("fff.download").download_or_build_binary() end,
    opts = {
      lazy_sync = true,
      keymaps = {
        select_tab = { "<C-t>", "<S-CR>" },
      },
    },
  },
  { 
    "nvim-telescope/telescope.nvim", 
    lazy = false,
    branch = "0.1.x", 
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
      "nvim-telescope/telescope-ui-select.nvim",
      { "nvim-telescope/telescope-frecency.nvim", version = "^1.0.0" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      local action_state = require("telescope.actions.state")

      local action_utils = require("telescope.actions.utils")

      local function harpoon_selected(prompt_bufnr)
        local ok, harpoon = pcall(require, "harpoon")
        if not ok then
          return
        end
        local picker = action_state.get_current_picker(prompt_bufnr)
        local selections = picker:get_multi_selection()
        if vim.tbl_isempty(selections) then
          selections = {}
          action_utils.map_entries(prompt_bufnr, function(entry)
            table.insert(selections, entry)
          end)
        end

        local list = harpoon:list()
        local seen = {}
        local count = 0
        for _, entry in ipairs(selections) do
          local raw = entry.path or entry.filename or entry.value
          if type(raw) == "table" then
            raw = raw.filename or raw.value
          end
          if type(raw) == "string" and raw ~= "" and vim.fn.isdirectory(raw) == 0 then
            local rel = vim.fn.fnamemodify(raw, ":.")
            if not seen[rel] then
              seen[rel] = true
              list:add({
                value = rel,
                context = {
                  row = entry.lnum or 1,
                  col = entry.col or 0,
                },
              })
              count = count + 1
            end
          end
        end

        actions.close(prompt_bufnr)
        vim.notify(string.format("Added %d file(s) to Harpoon", count), vim.log.levels.INFO)
      end

      telescope.setup({
        defaults = {
          initial_mode = "normal",
          mappings = {
            -- Enter = current window; Ctrl-t / Shift-Enter = new tab
            i = {
              ["<CR>"] = actions.select_default,
              ["<C-t>"] = actions.select_tab,
              ["<S-CR>"] = actions.select_tab,
              ["<C-q>"] = harpoon_selected,
            },
            n = {
              ["<CR>"] = actions.select_default,
              ["<C-t>"] = actions.select_tab,
              ["<S-CR>"] = actions.select_tab,
              ["<C-q>"] = harpoon_selected,
            },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
          frecency = {},
          ["ui-select"] = require("telescope.themes").get_dropdown({}),
        },
      })

      telescope.load_extension("fzf")
      telescope.load_extension("ui-select")
      telescope.load_extension("frecency")

      local function project_root()
        return vim.fs.root(0, { ".git" }) or vim.fn.getcwd()
      end
      vim.keymap.set("n", "<leader>sf", function()
        telescope.extensions.frecency.frecency({ cwd = project_root(), workspace = "CWD", hidden = true })
      end, { desc = "Find frecent files" })
      vim.keymap.set("n", "<leader>sF", function()
        require("telescope.builtin").find_files({ cwd = project_root() })
      end, { desc = "Find all files (Telescope)" })
      vim.keymap.set("n", "<leader>sg", function()
        require("telescope.builtin").live_grep({ cwd = project_root() })
      end, { desc = "Live grep (Telescope)" })
      vim.keymap.set("n", "<leader>sd", function()
        require("telescope.builtin").diagnostics()
      end, { desc = "Search diagnostics" })
    end
  },
  { 
    "nvim-treesitter/nvim-treesitter", 
    build = ":TSUpdate", 
    branch = "master",
    config = function() 
      require("nvim-treesitter.configs").setup({ 
        ensure_installed = {
          "c",
          "cpp",
          "c_sharp",
          "bash",
          "css",
          "diff",
          "graphql",
          "javascript",
          "jsdoc",
          "json",
          "json5",
          "query",
          "tsx",
          "typescript",
          "go",
          "gomod",
          "gosum",
          "gowork",
          "java",
          "lua",
          -- LSP hover/signature floats are markdown; without these parsers
          -- nvim 0.12's open_floating_preview errors and docs look broken.
          "markdown",
          "markdown_inline",
          "html",
          "typst",
          "yaml",
          "python",
          "rust",
          "vim",
          "vimdoc",
        },
        highlight = { enable = true } 
      }) 
    end 
  },
  {
    "ahmedkhalf/project.nvim",
    config = function()
      require("project_nvim").setup({})
      require("telescope").load_extension("projects")
    end
  },
  { "mbbill/undotree", lazy = false },
  {
    "okuuva/auto-save.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      debounce_delay = 1000,
      write_all_buffers = true,
      condition = function(buf)
        local fn = vim.fn
        local exclude_ft = { "gitcommit", "gitrebase" }
        if vim.tbl_contains(exclude_ft, vim.bo[buf].filetype) then return false end
        -- scratch/acwrite UI buffers (harpoon menu, pickers, terminals) have no file to write; writing them fires BufWriteCmd
        if vim.bo[buf].buftype ~= "" then return false end
        if fn.getbufvar(buf, "&modifiable") ~= 1 then return false end
        return true
      end,
    },
  },
  { "numToStr/Comment.nvim", opts = {}, lazy = false },
  { 
    "folke/trouble.nvim", 
    lazy = false,
    dependencies = { "nvim-mini/mini.nvim" },
    opts = {} 
  },
  { "kevinhwang91/nvim-hlslens", event = "VeryLazy", opts = {} },
  {
    "windwp/nvim-ts-autotag",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },
  {
    "Wansmer/treesj",
    keys = {
      { "<leader>tj", function() require("treesj").toggle() end, desc = "Toggle node layout" },
    },
    opts = { use_default_keymaps = false },
  },
  {
    "abecodes/tabout.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "L3MON4D3/LuaSnip" },
    event = "InsertCharPre",
    opts = { tabkey = "", backwards_tabkey = "" },
  },
  {
    "stevearc/quicker.nvim",
    ft = "qf",
    keys = {
      { "<leader>fq", function() require("quicker").toggle() end, desc = "Toggle quickfix" },
      { "<leader>fQ", function() require("quicker").toggle({ loclist = true }) end, desc = "Toggle location list" },
    },
    opts = {},
  },
  {
    "chrisgrieser/nvim-chainsaw",
    event = "VeryLazy",
    keys = {
      { "<leader>lg", function() require("chainsaw").variableLog() end, desc = "Log variable" },
    },
    opts = {},
  },
  {
    "MagicDuck/grug-far.nvim",
    cmd = { "GrugFar", "GrugFarWithin" },
    opts = { headerMaxWidth = 80 },
  },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
    },
  },
}
