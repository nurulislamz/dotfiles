-- Run: nvim --headless "+luafile test/nvim/clipboard.lua"
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
        print("PASS: nvim clipboard")
        vim.cmd("qa!")
        return
    end
    print("FAIL: " .. table.concat(failed, "; "))
    vim.cmd("cquit")
end

local function has_yank(text)
    local plus = vim.fn.getreg("+")
    return plus == text or plus == text .. "\n"
end

local function run()
    check("clipboard option empty", vim.o.clipboard == "")

    vim.cmd("enew")
    vim.bo.buftype = "nofile"
    vim.bo.swapfile = false
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "hello yank" })
    vim.cmd("normal! yy")
    vim.wait(50)
    check("yank sets +", has_yank("hello yank"))

    vim.fn.setreg("+", "keepme")
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    vim.cmd("normal x")
    check("x keeps +", vim.fn.getreg("+") == "keepme")

    vim.fn.setreg("+", "cliptext")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { "aaaa" })
    vim.cmd("normal 0viwp")
    check("visual p keeps +", vim.fn.getreg("+") == "cliptext")
    local line = vim.api.nvim_get_current_line()
    check("visual p inserted clipboard", line:find("cliptext", 1, true) ~= nil)

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
