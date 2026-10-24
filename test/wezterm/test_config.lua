-- Stub-load wezterm.lua for linux and windows triples. nvim --clean --headless.
local root = os.getenv("DOTFILES_ROOT") or os.getenv("ROOT")
if not root or root == "" then
    local src = debug.getinfo(1, "S").source:sub(2)
    root = src:match("(.+)/test/wezterm/")
end
assert(root, "DOTFILES_ROOT unset")

package.path = root .. "/wezterm/?.lua;" .. package.path

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

local function action_table()
    return setmetatable({}, {
        __index = function(t, k)
            local fn = function(...)
                return { kind = k, args = { ... } }
            end
            rawset(t, k, fn)
            return fn
        end,
    })
end

local function load_config(triple)
    local config = {}
    package.loaded.wezterm = nil
    package.preload.wezterm = function()
        return {
            target_triple = triple,
            config_builder = function()
                return config
            end,
            font_with_fallback = function(t)
                return t
            end,
            action = action_table(),
            on = function() end,
            plugin = {
                require = function()
                    return {
                        setup = function() end,
                        apply_to_config = function() end,
                        set_default_keys = function() end,
                    }
                end,
            },
        }
    end
    package.loaded["wezterm"] = package.preload.wezterm()
    local chunk, err = loadfile(root .. "/wezterm/wezterm.lua")
    assert(chunk, err)
    return chunk()
end

local function count_keys(cfg, pred)
    local n = 0
    for _, item in ipairs(cfg.keys or {}) do
        if pred(item) then
            n = n + 1
        end
    end
    return n
end

local function action_kind(item, kind, first)
    local act = item.action
    if type(act) ~= "table" then
        return false
    end
    if act.kind ~= kind then
        return false
    end
    if first ~= nil then
        return act.args[1] == first
    end
    return true
end

for _, triple in ipairs({
    "x86_64-unknown-linux-gnu",
    "x86_64-pc-windows-msvc",
}) do
    local cfg = load_config(triple)
    local tag = triple:find("windows") and "windows" or "linux"
    check(tag .. " returns table", type(cfg) == "table")
    check(tag .. " leader a+CTRL", cfg.leader and cfg.leader.key == "a" and cfg.leader.mods == "CTRL")
    check(tag .. " csi-u off", cfg.enable_csi_u_key_encoding == false)
    check(tag .. " kitty off", cfg.enable_kitty_keyboard == false)
    check(
        tag .. " shift-enter csi-u",
        count_keys(cfg, function(item)
            return item.key == "Enter" and item.mods == "SHIFT" and action_kind(item, "SendString", "\x1b[13;2u")
        end) == 1
    )
    check(
        tag .. " ctrl-b raw",
        count_keys(cfg, function(item)
            return (item.key == "b" or item.key == "B")
                and item.mods == "CTRL"
                and action_kind(item, "SendString", "\x02")
        end) >= 1
    )
    check(
        tag .. " ctrl-v after plugins",
        count_keys(cfg, function(item)
            return (item.key == "v" or item.key == "V")
                and item.mods == "CTRL"
                and action_kind(item, "EmitEvent", "paste-or-send")
        end) == 2
    )
    check(
        tag .. " ctrl-shift-v paste",
        count_keys(cfg, function(item)
            return item.key == "v" and item.mods == "CTRL|SHIFT" and action_kind(item, "PasteFrom")
        end) == 1
    )
    check(
        tag .. " copy-or-interrupt",
        count_keys(cfg, function(item)
            return item.key == "c" and item.mods == "CTRL" and action_kind(item, "EmitEvent", "copy-or-interrupt")
        end) == 1
    )
    if tag == "linux" then
        check("linux default_prog zsh", type(cfg.default_prog) == "table" and cfg.default_prog[1] == "zsh")
    else
        check("windows default_domain WSL", cfg.default_domain == "WSL:Ubuntu")
    end
end

if #failed > 0 then
    print("FAIL: wezterm stub " .. table.concat(failed, "; "))
    if vim and vim.cmd then
        vim.cmd("cquit")
    end
    os.exit(1)
end
print("PASS: wezterm stub")
if vim and vim.cmd then
    vim.cmd("qa")
end
