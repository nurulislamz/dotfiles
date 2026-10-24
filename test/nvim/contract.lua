-- Run: nvim --headless "+luafile test/nvim/contract.lua"
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

local function has_map(mode, lhs)
    return vim.fn.maparg(lhs, mode) ~= ""
end

local function finish()
    if #failed == 0 then
        print("PASS: nvim contract")
        vim.cmd("qa")
        return
    end
    print("FAIL: " .. table.concat(failed, "; "))
    vim.cmd("cquit")
end

local function run()
    print("")
    local lazy_ok, lazy_config = pcall(require, "lazy.core.config")
    check("lazy loaded", lazy_ok)
    if lazy_ok then
        local lock_path = vim.fn.stdpath("config") .. "/lazy-lock.json"
        local lock = vim.json.decode(table.concat(vim.fn.readfile(lock_path), "\n"))
        local missing = {}
        for name, _ in pairs(lock) do
            if name == "lazy.nvim" then
                goto continue
            end
            local plugin = lazy_config.plugins[name]
            if plugin ~= nil and vim.fn.isdirectory(plugin.dir) == 0 then
                table.insert(missing, name)
            end
            ::continue::
        end
        table.sort(missing)
        check("enabled lockfile plugins installed", #missing == 0, table.concat(missing, ", "))
    end

    for _, mod in ipairs({ "snacks", "oil", "glance", "fff", "hlslens", "gitsigns" }) do
        local loaded, err = pcall(require, mod)
        check("require " .. mod, loaded, err)
    end

    check("leader is space", vim.g.mapleader == " ")
    check("colorscheme cyberdream", vim.g.colors_name == "cyberdream")
    check("<leader>ff", has_map("n", "<leader>ff"))
    check("<leader>e", has_map("n", "<leader>e"))
    check("- oil", has_map("n", "-"))
    check("gd", has_map("n", "gd"))
    check("gr", has_map("n", "gr"))
    check("<C-h>", has_map("n", "<C-h>"))
    check("<leader>x", has_map("n", "<leader>x"))
    check("shift-enter csi-u mapping", has_map("n", "<Esc>[13;2u"))

    local fff_conf = require("fff.conf").get()
    local tab_keys = fff_conf and fff_conf.keymaps and fff_conf.keymaps.select_tab
    local fff_has_s_cr = false
    if type(tab_keys) == "table" then
        for _, k in ipairs(tab_keys) do
            if k == "<S-CR>" then fff_has_s_cr = true end
        end
    elseif tab_keys == "<S-CR>" then
        fff_has_s_cr = true
    end
    check("fff select_tab has <S-CR>", fff_has_s_cr)

    local oil_keys = require("oil.config").keymaps["<S-CR>"]
    check("oil <S-CR> tab", oil_keys ~= nil and oil_keys.opts ~= nil and oil_keys.opts.tab == true)

    local fzf_root = vim.fn.stdpath("data") .. "/lazy/telescope-fzf-native.nvim/build/"
    check(
        "telescope-fzf-native",
        vim.fn.filereadable(fzf_root .. "libfzf.so") == 1
            or vim.fn.filereadable(fzf_root .. "libfzf.dylib") == 1
            or vim.fn.filereadable(fzf_root .. "libfzf.dll") == 1
    )
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
