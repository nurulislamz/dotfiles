-- Auto-detect WezTerm inside tmux or direct (for terminal image rendering)
if vim.env.TMUX then
  local ok, termtype = pcall(vim.fn.system, { "tmux", "display-message", "-p", "#{client_termtype}" })
  if ok and termtype:lower():find("wezterm") then
    vim.env.SNACKS_WEZTERM = "1"
  end
elseif (vim.env.TERM_PROGRAM or ""):lower():find("wezterm") then
  vim.env.SNACKS_WEZTERM = "1"
end

return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  dependencies = { "nvim-mini/mini.nvim" },
  opts = {
    dashboard = { enabled = true },
    notifier = { enabled = true, timeout = 3000 },
    picker = {
      prompt = "   ",
      focus = "list",
      formatters = { file = { filename_first = true } },
      actions = {
        harpoon = function(picker)
          local ok, harpoon = pcall(require, "harpoon")
          if not ok then
            return
          end
          local list = harpoon:list()
          local sel = picker:selected()
          local items = #sel > 0 and sel or picker:items()
          local seen = {}
          local count = 0
          for _, item in ipairs(items) do
            if item then
              local path = Snacks.picker.util.path(item)
              if path and path ~= "" and vim.fn.isdirectory(path) == 0 then
                local rel_path = vim.fn.fnamemodify(path, ":.")
                if not seen[rel_path] then
                  seen[rel_path] = true
                  list:add({
                    value = rel_path,
                    context = {
                      row = item.pos and item.pos[1] or 1,
                      col = item.pos and item.pos[2] or 0,
                    },
                  })
                  count = count + 1
                end
              end
            end
          end
          picker:close()
          Snacks.notify.info(string.format("Added %d file(s) to Harpoon", count))
        end,
      },
      win = {
        input = {
          keys = {
            ["<S-CR>"] = { "tab", mode = { "n", "i" } },
            ["<c-q>"] = { "harpoon", mode = { "n", "i" } },
          },
        },
        list = {
          keys = {
            ["<S-CR>"] = { "tab", mode = { "n", "i" } },
            ["<c-q>"] = { "harpoon", mode = { "n", "i" } },
          },
        },
      },
      sources = {
        explorer = {
          win = {
            list = {
              keys = {
                ["<S-CR>"] = { "tab", mode = { "n", "i" } },
                ["<c-p>"] = { "toggle_preview", mode = { "n", "i" } },
              },
            },
          },
        },
      },
    },
    explorer = {
      replace_netrw = false,
    },
    lazygit = {
      configure = false,
      win = { position = "float", width = 0.99, height = 0.99 },
    },
    terminal = {
      win = { position = "right", width = 0.5, wo = { winbar = "" } },
    },
    image = {
      enabled = true,
      doc = {
        inline = true,
        float = true,
        max_height = 40,
        max_width = 80,
      },
    },
    words = { enabled = true, debounce = 100 },
    scratch = { enabled = true },
    zen = { enabled = true },
  },
}
