-- Run: nvim --headless -i NONE '+luafile test/nvim/reload.lua'
require("auto-save").off()
local path = vim.fn.tempname()
vim.fn.writefile({ "before" }, path)
vim.cmd.edit(path)
local buf = vim.api.nvim_get_current_buf()
vim.bo[buf].undofile = false

local function finish(ok, err)
    vim.api.nvim_buf_delete(buf, { force = true })
    vim.fn.delete(path)
    print(ok and "PASS: visible/hidden reload and unsaved-edit protection" or err)
    vim.cmd(ok and "qa!" or "cquit")
end

local function later(ms, fn)
    vim.defer_fn(function()
        local ok, err = pcall(fn)
        if not ok then finish(false, err) end
    end, ms)
end

local function contents()
    return vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1]
end

later(100, function()
    vim.fn.writefile({ "visible agent edit" }, path)
end)
later(1400, function()
    assert(contents() == "visible agent edit", "visible buffer stayed stale")
    vim.cmd.tabnew()
    vim.fn.writefile({ "hidden agent edit" }, path)
end)
later(2700, function()
    assert(contents() == "hidden agent edit", "hidden buffer stayed stale")
    vim.api.nvim_set_current_buf(buf)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "unsaved local edit" })
    vim.fn.writefile({ "conflicting agent edit" }, path)
end)
later(4000, function()
    assert(contents() == "unsaved local edit", "unsaved changes were discarded")
    assert(vim.fn.readfile(path)[1] == "conflicting agent edit", "agent changes were overwritten")
    assert(vim.bo[buf].modified, "unsaved buffer lost its modified flag")
    finish(true)
end)
