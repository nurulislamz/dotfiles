return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>", mode = { "n", "t" } },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>", mode = { "n", "t" } },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>", mode = { "n", "t" } },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>", mode = { "n", "t" } },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>", mode = { "n", "t" } },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-mini/mini.nvim" },
    opts = {
      sections = {
        lualine_c = {
          {
            "filename",
            path = 1, -- 0: Just filename, 1: Relative path, 2: Absolute path, 3: Absolute path with ~, 4: Filename and parent dir
          },
        },
      },
    },
  },

  {
    "scottmckendry/cyberdream.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("cyberdream").setup({
        transparent = false,
        italic_comments = true,
        hide_fillchars = true,
        borderless_pickers = true,
        terminal_colors = true,
      })
      vim.cmd("colorscheme cyberdream")
    end,
  },
  { 
    "folke/which-key.nvim", 
    lazy = false,
    priority = 900,
    init = function() 
      vim.o.timeout = true 
      vim.o.timeoutlen = 500 
    end, 
    opts = {
      preset = "classic",
      icons = { mappings = false, rules = false },
      spec = {
        mode = { "n", "v" },
        { "<leader><Tab>", group = "tabs" },
        { "<leader>c", group = "code / git" },
        { "<leader>f", group = "file/find" },
        { "<leader>g", group = "goto / lsp" },
        { "<leader>h", group = "harpoon" },
        { "<leader>m", group = "markdown" },
        { "<leader>S", group = "session" },
        { "<leader>t", group = "toggle" },
        { "<leader>w", group = "window" },
        { "<leader>1", hidden = true },
        { "<leader>2", hidden = true },
        { "<leader>3", hidden = true },
        { "<leader>4", hidden = true },
        { "<leader>p", desc = "Search paste buffer" },
        { "<leader>e", desc = "File explorer (Snacks)" },
        { "<leader>.", desc = "Scratch buffer" },
      },
    },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    config = function()
      require("noice").setup({
        lsp = {
          progress = { enabled = false },
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true, 
            ["vim.lsp.util.stylize_markdown"] = true, 
          } 
        },
        -- Route common messages to 'mini' (bottom right) instead of a popup
        routes = {
          {
            view = "mini",
            filter = { event = "msg_show", kind = "", find = "written" },
          },
        },
        presets = { bottom_search = true, command_palette = true, long_message_to_split = true, inc_rename = true },
        views = {
          notify = { timeout = 1000 },
        },
      })
    end
  },
  {
    "akinsho/bufferline.nvim",
    event = { "BufReadPost", "BufNewFile" },
    keys = {
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Tab" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Tab" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Tab" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Tab" },
    },
    opts = function()
      local colors = require("cyberdream.colors").default
      return {
        options = {
          mode = "tabs",
          style_preset = require("bufferline").style_preset.minimal,
          separator_style = "slant",
          show_buffer_close_icons = false,
          show_close_icon = false,
          always_show_bufferline = true,
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(count, level)
            local icon = level:match("error") and "󰅚 " or (level:match("warning") and "󰅐 " or "󰌵 ")
            return " " .. icon .. count
          end,
          modified_icon = "●",
          offsets = {
            {
              filetype = "snacks_layout_box",
              text = "File Explorer",
              highlight = "Directory",
              text_align = "left",
              separator = true,
            },
          },
        },
        highlights = {
          fill = { bg = colors.bg },
          background = { fg = colors.grey, bg = colors.bg },
          buffer_visible = { fg = colors.grey, bg = colors.bg },
          buffer_selected = { fg = colors.bg, bg = colors.blue, bold = true, italic = false },
          separator = { fg = colors.bg_highlight, bg = colors.bg },
          separator_selected = { fg = colors.bg, bg = colors.blue },
          separator_visible = { fg = colors.bg_highlight, bg = colors.bg },
          indicator_selected = { fg = colors.blue, bg = colors.blue },
          indicator_visible = { fg = colors.bg, bg = colors.bg },
          modified = { fg = colors.orange, bg = colors.bg },
          modified_selected = { fg = colors.bg, bg = colors.blue },
          modified_visible = { fg = colors.orange, bg = colors.bg },
          diagnostic = { fg = colors.grey, bg = colors.bg },
          diagnostic_visible = { fg = colors.grey, bg = colors.bg },
          diagnostic_selected = { fg = colors.bg, bg = colors.blue, bold = true },
          error = { fg = colors.red, bg = colors.bg },
          error_visible = { fg = colors.red, bg = colors.bg },
          error_selected = { fg = colors.bg, bg = colors.blue, bold = true },
          warning = { fg = colors.yellow, bg = colors.bg },
          warning_visible = { fg = colors.yellow, bg = colors.bg },
          warning_selected = { fg = colors.bg, bg = colors.blue, bold = true },
          info = { fg = colors.blue, bg = colors.bg },
          info_visible = { fg = colors.blue, bg = colors.bg },
          info_selected = { fg = colors.bg, bg = colors.blue, bold = true },
          hint = { fg = colors.cyan, bg = colors.bg },
          hint_visible = { fg = colors.cyan, bg = colors.bg },
          hint_selected = { fg = colors.bg, bg = colors.blue, bold = true },
        },
      }
    end,
  },
}
