local M = {}
local watchers = {}
local timer
local pending = false

local function refresh()
    if not timer or vim.fn.mode() == "c" or vim.fn.getcmdwintype() ~= "" then return end
    pending = false
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and not vim.bo[buf].modified then
            vim.cmd("checktime " .. buf)
        end
    end
end

function M.stop()
    if timer then
        timer:stop()
        timer:close()
        timer = nil
    end
    for dir, watcher in pairs(watchers) do
        watcher:stop()
        watcher:close()
        watchers[dir] = nil
    end
    pending = false
end

local function update()
    if not timer then return end
    local dirs = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(buf)
        if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and name ~= "" then
            dirs[vim.fs.dirname(name)] = true
        end
    end
    for dir, watcher in pairs(watchers) do
        if not dirs[dir] then
            watcher:stop()
            watcher:close()
            watchers[dir] = nil
        end
    end
    for dir in pairs(dirs) do
        if not watchers[dir] then
            local watcher = assert(vim.uv.new_fs_event())
            local ok, err = watcher:start(dir, {}, function(watch_error)
                if watch_error then
                    vim.schedule(function()
                        vim.notify_once("File watcher failed for " .. dir .. ": " .. watch_error, vim.log.levels.WARN)
                    end)
                    return
                end
                if not timer then return end
                pending = true
                timer:start(500, 0, vim.schedule_wrap(refresh))
            end)
            if ok then
                watchers[dir] = watcher
            else
                watcher:close()
                vim.notify("Cannot watch " .. dir .. ": " .. tostring(err), vim.log.levels.WARN)
            end
        end
    end
end

function M.setup()
    M.stop()
    vim.opt.autoread = true
    timer = assert(vim.uv.new_timer())
    local group = vim.api.nvim_create_augroup("disk_reload", { clear = true })
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufFilePost", "BufUnload" }, {
        group = group,
        callback = vim.schedule_wrap(update),
    })
    vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
        group = group,
        callback = vim.schedule_wrap(function()
            update()
            refresh()
        end),
    })
    vim.api.nvim_create_autocmd({ "CmdlineLeave", "CmdwinLeave" }, {
        group = group,
        callback = vim.schedule_wrap(function()
            if pending then refresh() end
        end),
    })
    vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = M.stop })
    update()
end

return M
