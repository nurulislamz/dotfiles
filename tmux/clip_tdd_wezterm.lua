-- Isolated WezTerm config for clip_paste_test (no resurrect/plugins).
-- Ctrl+V contract must match dotfiles/wezterm/wezterm.lua.
local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action
config.wsl_domains = {
    {
        name = "WSL:Ubuntu",
        distribution = "Ubuntu",
        default_cwd = "~",
        default_prog = { "zsh" },
    },
}
config.default_domain = "WSL:Ubuntu"
config.allow_win32_input_mode = false
config.enable_csi_u_key_encoding = false
config.enable_kitty_keyboard = false
-- This GUI is spawned without tmux. Always paste the Windows clipboard.
config.keys = {
    { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
    { key = "c", mods = "CTRL", action = wezterm.action.EmitEvent("copy-or-interrupt") },
    { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
    { key = "V", mods = "CTRL", action = act.PasteFrom("Clipboard") },
}
wezterm.on("copy-or-interrupt", function(window, pane)
    local sel = window:get_selection_text_for_pane(pane)
    if sel and sel ~= "" then
        window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
        window:perform_action(act.ClearSelection, pane)
    else
        window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
    end
end)
return config
