return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local harpoon = require("harpoon")

      harpoon:setup({
        settings = {
          save_on_toggle = true,
          sync_on_ui_close = true,
        },
      })

      -- Add current file to Harpoon
      vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end, { desc = "Harpoon add file" })

      -- Quick menu (toggle list); persists until explicitly closed (q / <Esc> / <C-e> / <CR>)
      vim.keymap.set("n", "<C-e>", function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
        if harpoon.ui.bufnr then
          vim.keymap.set("n", "<S-CR>", function()
            harpoon.ui:select_menu_item({ tabedit = true })
          end, { buffer = harpoon.ui.bufnr, silent = true, desc = "Harpoon open in new tab" })
          -- harpoon closes the menu on any BufLeave; drop it so only an explicit close ends the menu
          vim.api.nvim_clear_autocmds({
            group = require("harpoon.autocmd"),
            event = "BufLeave",
            buffer = harpoon.ui.bufnr,
          })
        end
      end, { desc = "Harpoon quick menu" })

      -- Direct file jumps 1-4 (<leader>1..<leader>4 and <leader>h1..<leader>h4)
      vim.keymap.set("n", "<leader>1", function() harpoon:list():select(1) end, { desc = "Harpoon file 1" })
      vim.keymap.set("n", "<leader>2", function() harpoon:list():select(2) end, { desc = "Harpoon file 2" })
      vim.keymap.set("n", "<leader>3", function() harpoon:list():select(3) end, { desc = "Harpoon file 3" })
      vim.keymap.set("n", "<leader>4", function() harpoon:list():select(4) end, { desc = "Harpoon file 4" })

      vim.keymap.set("n", "<leader>h1", function() harpoon:list():select(1) end, { desc = "Harpoon file 1" })
      vim.keymap.set("n", "<leader>h2", function() harpoon:list():select(2) end, { desc = "Harpoon file 2" })
      vim.keymap.set("n", "<leader>h3", function() harpoon:list():select(3) end, { desc = "Harpoon file 3" })
      vim.keymap.set("n", "<leader>h4", function() harpoon:list():select(4) end, { desc = "Harpoon file 4" })

      -- Ctrl+number navigation fallback
      vim.keymap.set("n", "<C-1>", function() harpoon:list():select(1) end, { desc = "Harpoon file 1" })
      vim.keymap.set("n", "<C-2>", function() harpoon:list():select(2) end, { desc = "Harpoon file 2" })
      vim.keymap.set("n", "<C-3>", function() harpoon:list():select(3) end, { desc = "Harpoon file 3" })
      vim.keymap.set("n", "<C-4>", function() harpoon:list():select(4) end, { desc = "Harpoon file 4" })

      -- Next / Previous file in list
      vim.keymap.set("n", "]h", function() harpoon:list():next() end, { desc = "Harpoon next file" })
      vim.keymap.set("n", "[h", function() harpoon:list():prev() end, { desc = "Harpoon prev file" })

      -- Telescope picker
      vim.keymap.set("n", "<leader>fh", function()
        local conf = require("telescope.config").values
        local file_paths = {}
        for _, item in ipairs(harpoon:list().items) do
          table.insert(file_paths, item.value)
        end
        require("telescope.pickers").new({}, {
          prompt_title = "Harpoon",
          finder = require("telescope.finders").new_table({ results = file_paths }),
          previewer = conf.file_previewer({}),
          sorter = conf.generic_sorter({}),
        }):find()
      end, { desc = "Harpoon list picker (Telescope)" })
    end,
  },
}
