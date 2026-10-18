return {
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- only start saving once a real file is opened
    opts = {
      need = 1,
      branch = true,
    },
    init = function()
      -- Reopen the last workspace for this cwd when starting Neovim without args
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("persistence_autoload", { clear = true }),
        nested = true,
        callback = function()
          if vim.fn.argc(-1) > 0 then
            return
          end
          vim.schedule(function()
            require("persistence").load()
          end)
        end,
      })
      -- Do not persist sessions when opening task.md or scratch task files
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("persistence_task_ignore", { clear = true }),
        pattern = { "*/task.md", "*tasklogs/*.md", "task.md" },
        callback = function()
          pcall(function()
            require("persistence").stop()
          end)
        end,
      })
      -- Close floating windows (e.g. Snacks dashboard) before loading session to prevent E5601
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceLoadPre",
        callback = function()
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local cfg = vim.api.nvim_win_get_config(win)
            if cfg.relative ~= "" then
              pcall(vim.api.nvim_win_close, win, true)
            end
          end
        end,
      })
      -- Wipe dashboard scratch buffers after session load
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceLoadPost",
        callback = function()
          for _, b in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[b].filetype:find("^snacks_") then
              pcall(vim.api.nvim_buf_delete, b, { force = true })
            end
          end
        end,
      })
      -- Close explorer before saving sessions so zombie buffers aren't restored
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceSavePre",
        callback = function()
          pcall(function()
            local snacks = package.loaded["snacks"]
            if snacks and snacks.picker then
              local explorer = snacks.picker.get({ source = "explorer" })[1]
              if explorer then
                explorer:close()
              end
            end
          end)
        end,
      })
    end,
  },
}
