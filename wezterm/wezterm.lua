-- Initialize Configuration
local wezterm = require("wezterm")
local config = wezterm.config_builder()
local opacity = 1
local transparent_bg = "rgba(22, 24, 26, " .. opacity .. ")"

--- Get the current operating system
--- @return "windows" | "linux" | "macos"
local function get_os()
    if wezterm.target_triple:find("windows") then
        return "windows"
    elseif wezterm.target_triple:find("linux") then
        return "linux"
    end
    return "macos"
end

local host_os = get_os()

-- Font Configuration
local emoji_font = host_os == "windows" and "Segoe UI Emoji" or "Noto Color Emoji"
config.font = wezterm.font_with_fallback({
    {
        family = "Cascadia Code",
        weight = "Regular",
    },
    "JetBrainsMono Nerd Font",
    "JetBrains Mono",
    "Consolas",
    emoji_font,
})
config.font_size = 10

-- Color Configuration
config.colors = require("cyberdream")
config.force_reverse_video_cursor = true

-- Window Configuration
config.initial_rows = 45
config.initial_cols = 180
config.window_decorations = "RESIZE"
config.window_background_opacity = opacity
config.window_background_image = (os.getenv("WEZTERM_CONFIG_FILE") or ""):gsub("wezterm.lua", "bg-blurred.png")
config.window_close_confirmation = "NeverPrompt"
config.win32_system_backdrop = "Acrylic"

-- Performance Settings
config.max_fps = 144
config.animation_fps = 60
config.cursor_blink_rate = 250

-- Tab Bar Configuration
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.show_tab_index_in_tab_bar = false
config.use_fancy_tab_bar = false
config.colors.tab_bar = {
    background = config.window_background_image and "rgba(0, 0, 0, 0)" or transparent_bg,
    new_tab = { fg_color = config.colors.background, bg_color = config.colors.brights[6] },
    new_tab_hover = { fg_color = config.colors.background, bg_color = config.colors.foreground },
}

-- Tab Formatting
wezterm.on("format-tab-title", function(tab, _, _, _, hover)
    local background = config.colors.brights[1]
    local foreground = config.colors.foreground

    if tab.is_active then
        background = config.colors.brights[7]
        foreground = config.colors.background
    elseif hover then
        background = config.colors.brights[8]
        foreground = config.colors.background
    end

    local title = tostring(tab.tab_index + 1)
    return {
        { Foreground = { Color = background } },
        { Text = "█" },
        { Background = { Color = background } },
        { Foreground = { Color = foreground } },
        { Text = title },
        { Foreground = { Color = background } },
        { Text = "█" },
    }
end)

-- Keybindings
local act = wezterm.action

config.keys = {
    { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },
    { key = "Insert", mods = "SHIFT", action = act.PasteFrom("Clipboard") },
    -- Shift+Enter: send CSI u sequence (\x1b[13;2u) for newline in agy, TUIs, and shells
    { key = "Enter", mods = "SHIFT", action = act.SendString("\x1b[13;2u") },
    { key = "CapsLock", action = act.SendKey({ key = "Escape" }) },
}

-- macOS keeps default Cmd+C/Cmd+V, so Ctrl+C/Ctrl+V reach the shell and Neovim.
if host_os ~= "macos" then
    table.insert(config.keys, { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") })
    table.insert(config.keys, {
        key = "c",
        mods = "CTRL",
        action = wezterm.action_callback(function(window, pane)
            local sel = window:get_selection_text_for_pane(pane)
            if sel and sel ~= "" then
                window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
                window:perform_action(act.ClearSelection, pane)
            else
                window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
            end
        end),
    })
end

-- Default Shell / Domain Configuration
if host_os == "windows" then
    config.wsl_domains = {
        {
            name = "WSL:Ubuntu",
            distribution = "Ubuntu",
            default_cwd = "~",
            default_prog = { "zsh" },
        },
    }
    config.default_domain = "WSL:Ubuntu"
elseif host_os == "linux" then
    config.default_prog = { "zsh" }
    config.front_end = "WebGpu"
    config.window_background_image = os.getenv("HOME") .. "/.config/wezterm/bg-blurred.png"
    config.window_decorations = nil -- use system decorations
else
    config.default_prog = { "zsh" }
end

-- Quick Select Patterns
config.quick_select_patterns = {
    -- UUIDs
    "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}",
    -- Alphanumeric tokens / hashes / container IDs (min 8 chars)
    "[a-zA-Z0-9_-]{8,}",
    -- IP with optional port
    "\\b\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}(?::\\d+)?\\b",
    -- Hex colors
    "#[0-9a-fA-F]{6}\\b",
    -- Env vars
    "\\$[A-Z_][A-Z0-9_]*",
    -- Quoted strings
    '"[^"]+"',
    "'[^']+'",
}

-- Plugins (leader required by replay + cmdpicker)
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

local resurrect = wezterm.plugin.require("https://github.com/StephenGemin/resurrect.wezterm")
resurrect.setup(config, { status_bar = false })

local modal = wezterm.plugin.require("https://github.com/MLFlexer/modal.wezterm")
modal.apply_to_config(config)
modal.set_default_keys(config)
wezterm.on("modal.enter", function(name, window, pane)
    modal.set_right_status(window, name)
    modal.set_window_title(pane, name)
end)
wezterm.on("modal.exit", function(_, window, pane)
    window:set_right_status("")
    modal.reset_window_title(pane)
end)

local wezterm_replay = wezterm.plugin.require("https://github.com/btrachey/wezterm-replay")
wezterm_replay.apply_to_config(config)

local cmdpicker = wezterm.plugin.require("https://github.com/abidibo/wezterm-cmdpicker")
cmdpicker.apply_to_config(config, { title = "Command Palette" })

return config
