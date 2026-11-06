return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  lazy = false,
  dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
  opts = {
    window = {
      mappings = {
        ["s"] = "none",
        ["<C-p>"] = { "toggle_preview", config = { use_float = true, use_snacks_image = true } },
        ["<C-l>"] = "focus_preview",
        ["<C-s>"] = "open_leftabove_vs",
        ["<C-v>"] = "open_split",
        ["<C-CR>"] = "open_tabnew",
      },
    },
    filesystem = {
      follow_current_file = { enabled = true },
      hijack_netrw_behavior = "open_current",
      window = {
        mappings = {
          ["I"] = "toggle_hidden",
          ["<C-k>"] = "navigate_up",
        },
      },
    },
  },
}
