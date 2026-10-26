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
      -- Retired workmux task logs. A saved session or ShaDa oldfile must not
      -- reopen them, and VimLeave must not write them back into the session.
      local function is_tasklog(path)
        return path:find("/workmux/tasklogs/", 1, true) ~= nil
          or path:find("/%.workmux/task%.md$") ~= nil
      end
      local function drop_tasklogs()
        vim.v.oldfiles = vim.tbl_filter(function(f)
          return not is_tasklog(f)
        end, vim.v.oldfiles)
        local cur = vim.api.nvim_buf_get_name(0)
        if cur ~= "" and is_tasklog(cur) then
          local replacement
          for _, b in ipairs(vim.api.nvim_list_bufs()) do
            local n = vim.api.nvim_buf_get_name(b)
            if n ~= "" and not is_tasklog(n) and vim.bo[b].buftype == "" and vim.fn.filereadable(n) == 1 then
              replacement = b
              break
            end
          end
          if replacement then
            pcall(vim.api.nvim_set_current_buf, replacement)
          else
            vim.cmd("enew")
          end
        end
        for _, b in ipairs(vim.api.nvim_list_bufs()) do
          local n = vim.api.nvim_buf_get_name(b)
          if n ~= "" and is_tasklog(n) then
            pcall(vim.api.nvim_buf_delete, b, { force = true })
          end
        end
      end
      -- Reopen the last workspace for this cwd when starting Neovim without args
      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("persistence_autoload", { clear = true }),
        nested = true,
        callback = function()
          drop_tasklogs()
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
          drop_tasklogs()
          -- Land on the file you had open last. Session focus can be a plugin
          -- scratch buffer, and a stale session file must not win over your
          -- most recently opened file (ShaDa v:oldfiles).
          local function real_file(b)
            local n = vim.api.nvim_buf_get_name(b)
            if
              vim.bo[b].buftype == ""
              and n ~= ""
              and not n:find("^%a[%w+.-]*://")
              and vim.fn.filereadable(n) == 1
            then
              return n
            end
          end
          local target, rank
          for _, b in ipairs(vim.api.nvim_list_bufs()) do
            local n = real_file(b)
            if n then
              for i, f in ipairs(vim.v.oldfiles) do
                if f == n and (not rank or i < rank) then
                  target, rank = b, i
                  break
                end
              end
            end
          end
          if target and target ~= vim.api.nvim_get_current_buf() and not vim.bo.modified then
            local win = vim.fn.win_findbuf(target)[1]
            if not win then
              for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
                if vim.api.nvim_win_get_config(w).relative == "" then
                  win = w
                  break
                end
              end
            end
            if win then
              pcall(vim.api.nvim_win_set_buf, win, target)
              pcall(vim.api.nvim_set_current_win, win)
            end
          end
        end,
      })
      -- Close explorer before saving sessions so zombie buffers aren't restored
      vim.api.nvim_create_autocmd("User", {
        pattern = "PersistenceSavePre",
        callback = function()
          drop_tasklogs()
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
