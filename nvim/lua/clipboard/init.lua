-- Personal clipboard: p always pastes +, yanks sync to +/tmux,
-- deletes go to + (empty dd / x / X → black hole), <leader>p picks registers.
local M = {}

local function search_paste_buffer()
    local registers = { '"', "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "+" }
    local items = {}
    local seen = {}
    for _, reg in ipairs(registers) do
        local content = vim.fn.getreg(reg)
        if content and content:match("%S") and not seen[content] then
            seen[content] = true
            local preview = content:gsub("[\r\n]+", " "):sub(1, 80)
            local label = string.format("[%s] %s", reg, preview)
            table.insert(items, { reg = reg, label = label, content = content })
        end
    end

    if #items == 0 then
        vim.notify("Paste buffer is empty", vim.log.levels.INFO, { title = "Paste Buffer" })
        return
    end

    local labels = {}
    for _, item in ipairs(items) do
        table.insert(labels, item.label)
    end

    vim.ui.select(labels, { prompt = "Search Paste Buffer:" }, function(choice)
        if not choice then return end
        for _, item in ipairs(items) do
            if item.label == choice then
                local lines = vim.split(item.content, "\n", { plain = true })
                if #lines > 1 and lines[#lines] == "" then table.remove(lines) end
                local regtype = vim.fn.getregtype(item.reg)
                vim.api.nvim_put(lines, regtype == "V" and "l" or "c", true, true)
                break
            end
        end
    end)
end

function M.setup()
    -- Empty clipboard keeps deletions/edits inside Vim registers without polluting the OS clipboard.
    vim.opt.clipboard = ""

    local yank_sync_group = vim.api.nvim_create_augroup("YankClipboardSync", { clear = true })
    vim.api.nvim_create_autocmd("TextYankPost", {
        group = yank_sync_group,
        desc = "Sync yanks to system clipboard and tmux buffer",
        callback = function()
            -- Only explicit yanks (not deletes or changes) sync to system clipboard and tmux buffer.
            if vim.v.event.operator == "y" then
                pcall(vim.fn.setreg, "+", vim.fn.getreg('"'), vim.fn.getregtype('"'))
                if vim.env.TMUX ~= nil then
                    local text = table.concat(vim.v.event.regcontents, "\n")
                    if #text > 0 then
                        pcall(vim.fn.system, { "tmux", "load-buffer", "-" }, text)
                    end
                end
            end
        end,
    })

    local map = vim.keymap.set

    -- Always paste from system register '+' so external copies and internal yanks work identically.
    map("n", "p", '"+p', { desc = "Paste clipboard after cursor" })
    map("n", "P", '"+P', { desc = "Paste clipboard before cursor" })
    -- Overwrite visual selection without replacing clipboard with deleted text.
    map("x", "p", '"_d"+P', { desc = "Paste clipboard over selection (keep clipboard)" })
    map("x", "P", '"_d"+P', { desc = "Paste clipboard over selection (keep clipboard)" })
    map("v", "<C-c>", '"+y', { desc = "Copy selection to clipboard" })

    -- Black-hole single char deletes so they do not overwrite yank register.
    map("n", "x", '"_x', { desc = "Delete char to black hole" })
    map("n", "X", '"_X', { desc = "Backspace char to black hole" })
    -- Blank-line dd goes to black hole; non-blank goes to '+' clipboard.
    map("n", "dd", function()
        if vim.api.nvim_get_current_line():match("^%s*$") then
            return '"_dd'
        else
            return '"+dd'
        end
    end, { expr = true, desc = "Smart delete line (empty → black hole, else → clipboard)" })
    map("n", "d", '"+d', { desc = "Delete motion to clipboard" })
    map("n", "D", '"+D', { desc = "Delete to EOL to clipboard" })
    map("x", "d", '"+d', { desc = "Delete selection to clipboard" })

    map("n", "<leader>p", search_paste_buffer, { desc = "Search paste buffer" })
end

return M
