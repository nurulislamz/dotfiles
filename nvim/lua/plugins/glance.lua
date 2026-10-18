local function is_current_loc(loc)
  local uri = loc.uri or loc.targetUri
  if not uri then return false end
  local target_path = vim.fs.normalize(vim.uri_to_fname(uri))
  local cur_path = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
  if target_path ~= cur_path then return false end
  local range = loc.targetSelectionRange or loc.targetRange or loc.range
  if not range then return false end
  local cur_line = vim.api.nvim_win_get_cursor(0)[1] - 1
  return range.start.line == cur_line
end

return {
  {
    "dnlhc/glance.nvim",
    cmd = "Glance",
    keys = {
      { "gd", "<cmd>Glance definitions<CR>", desc = "Smart Go-to-Definition" },
      { "gr", "<cmd>Glance references<CR>", desc = "Go to References" },
      { "gi", "<cmd>Glance implementations<CR>", desc = "Go to Implementation" },
      { "gy", "<cmd>Glance type_definitions<CR>", desc = "Go to Type Definition" },
    },
    opts = function()
      local actions = require("glance").actions
      return {
        border = {
          enable = true,
          top_char = "―",
          bottom_char = "―",
        },
        theme = {
          mode = "auto",
        },
        mappings = {
          list = {
            ["<leader>q"] = actions.close,
            ["<S-CR>"] = actions.jump_tab,
          },
          preview = {
            ["<leader>q"] = actions.close,
          },
        },
        hooks = {
          before_open = function(results, open, jump, method)
            if method == "definitions" then
              local all_at_root = #results > 0
              for _, loc in ipairs(results) do
                if not is_current_loc(loc) then
                  all_at_root = false
                  break
                end
              end

              if all_at_root then
                vim.notify("Already at definition, showing references...", vim.log.levels.INFO, { title = "LSP" })
                require("glance").open("references")
                return
              end
            end

            if #results == 1 and method ~= "references" then
              jump(results[1])
            else
              open(results)
            end
          end,
        },
      }
    end,
  },
}
