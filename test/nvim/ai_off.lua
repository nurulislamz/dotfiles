-- Run: NVIM_AI_COMPLETION=off nvim --headless "+luafile test/nvim/ai_off.lua"
local failed = {}

local function check(name, cond, detail)
    if cond then
        print("ok: " .. name)
        return
    end
    local msg = name .. (detail and (": " .. tostring(detail)) or "")
    table.insert(failed, msg)
    print("FAIL: " .. msg)
end

local function finish()
    if #failed == 0 then
        print("PASS: nvim ai off")
        vim.cmd("qa")
        return
    end
    print("FAIL: " .. table.concat(failed, "; "))
    vim.cmd("cquit")
end

local function run()
    check("ai_completion off", vim.g.ai_completion == "off")
    check("ai_neocursor false", vim.g.ai_neocursor == false)
    check("ai_copilot false", vim.g.ai_copilot == false)
    check("neocursor module unloaded", package.loaded["neocursor"] == nil)
    check("copilot module unloaded", package.loaded["copilot"] == nil)
    finish()
end

local ran = false
local function once()
    if ran then
        return
    end
    ran = true
    local ok, err = pcall(run)
    if not ok then
        print("FAIL: " .. tostring(err))
        vim.cmd("cquit")
    end
end

vim.api.nvim_create_autocmd("User", { pattern = "VeryLazy", once = true, callback = once })
if vim.v.vim_did_enter == 1 then
    vim.schedule(once)
end
vim.defer_fn(once, 5000)
