return {
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- only start saving once a real file is opened
    opts = {
      need = 1,
      branch = true,
    },
    init = function()
      -- Persistence names sessions from getcwd(), but project.nvim cds to the
      -- detected project root on BufEnter, so saves otherwise land on another
      -- session and the launch dir keeps restoring a stale one. Anchor both
      -- save and load to the dir nvim was started in.
      local start_dir = vim.fn.getcwd()
      local function in_start_dir(fn)
        local cwd = vim.fn.getcwd()
        if cwd ~= start_dir then
          pcall(vim.cmd.cd, vim.fn.fnameescape(start_dir))
        end
        local ok, err = pcall(fn)
        if vim.fn.getcwd() ~= cwd and vim.fn.isdirectory(cwd) == 1 then
          pcall(vim.cmd.cd, vim.fn.fnameescape(cwd))
        end
        if not ok then
          vim.notify("persistence: " .. tostring(err), vim.log.levels.WARN)
        end
      end
      -- Reopen the last workspace for this cwd when starting Neovim without args
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("persistence_autoload", { clear = true }),
        nested = true,
        callback = function()
          if vim.fn.argc(-1) > 0 then
            return
          end
          vim.schedule(function()
            in_start_dir(function()
              require("persistence").load()
            end)
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
          -- Scratch buffers (codediff panes, plugin scratch) must not stay focused
          local cur = vim.api.nvim_get_current_buf()
          local name = vim.api.nvim_buf_get_name(cur)
          local scratch = vim.bo[cur].buftype ~= ""
            or name == ""
            or name:find("^%a[%w+.-]*://")
            or vim.fn.filereadable(name) == 0
          if scratch and not vim.bo[cur].modified then
            local target, best_used
            for _, b in ipairs(vim.api.nvim_list_bufs()) do
              local n = vim.api.nvim_buf_get_name(b)
              if
                #vim.fn.win_findbuf(b) > 0
                and vim.bo[b].buftype == ""
                and n ~= ""
                and not n:find("^%a[%w+.-]*://")
                and vim.fn.filereadable(n) == 1
              then
                local used = (vim.fn.getbufinfo(b)[1] or {}).lastused or 0
                if not target or used > best_used or (used == best_used and b > target) then
                  target, best_used = b, used
                end
              end
            end
            if target then
              pcall(vim.api.nvim_set_current_win, vim.fn.win_findbuf(target)[1])
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
          -- project.nvim may have cd'd away; pin the save to the launch dir so
          -- the session keeps the name it was loaded from.
          pcall(vim.cmd.cd, vim.fn.fnameescape(start_dir))
        end,
      })
    end,
  },
}
