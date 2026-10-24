import json
import os
import re
from pathlib import Path
import pytest

ZED_DIR = str(Path(__file__).resolve().parent)
SETTINGS_PATH = os.path.join(ZED_DIR, "settings.json")
KEYMAP_PATH = os.path.join(ZED_DIR, "keymap.json")
TASKS_PATH = os.path.join(ZED_DIR, "tasks.json")
WIN_ROAMING_DIR = "/mnt/c/Users/nurul/AppData/Roaming/Zed"
WSL_CONFIG_DIR = str(Path.home() / ".config/zed")

VALID_ACTIONS = {
    "editor::Cancel",
    "editor::Format",
    "editor::FormatSelections",
    "editor::GoToDefinition",
    "editor::GoToDefinitionSplit",
    "editor::FindAllReferences",
    "editor::GoToImplementation",
    "editor::GoToImplementationSplit",
    "editor::GoToTypeDefinition",
    "editor::Hover",
    "editor::Rename",
    "editor::ToggleCodeActions",
    "editor::GoToDiagnostic",
    "editor::GoToPrevDiagnostic",
    "editor::RestartLanguageServer",
    "editor::DeleteToPreviousWordStart",
    "workspace::ActivatePaneInDirection",
    "workspace::NewFile",
    "workspace::Save",
    "pane::DeploySearch",
    "pane::SplitRight",
    "pane::SplitDown",
    "pane::CloseActiveItem",
    "pane::CloseInactiveItems",
    "pane::ActivateNextItem",
    "pane::ActivatePrevItem",
    "pane::ActivateItem",
    "pane::TogglePinTab",
    "file_finder::Toggle",
    "project_panel::ToggleFocus",
    "project_panel::CollapseSelectedEntry",
    "project_panel::ExpandSelectedEntry",
    "project_panel::Open",
    "menu::SelectNext",
    "menu::SelectPrev",
    "diagnostics::Deploy",
    "outline::Toggle",
    "project_symbols::Toggle",
    "markdown::OpenPreview",
    "markdown::OpenPreviewToTheSide",
    "tab_switcher::Toggle",
    "assistant::InlineAssist",
    "assistant::ToggleFocus",
    "workspace::FocusCenterPane",
}


@pytest.fixture(scope="module")
def settings():
    with open(SETTINGS_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


@pytest.fixture(scope="module")
def keymap():
    with open(KEYMAP_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


@pytest.fixture(scope="module")
def tasks():
    with open(TASKS_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


def _get_bindings_by_context(keymap, context_substr):
    for block in keymap:
        if context_substr in block.get("context", ""):
            return block.get("bindings", {})
    return {}


# ==============================================================================
# Seam 1: Action Validity & Schema
# ==============================================================================
def test_all_actions_valid(keymap):
    """Verify that every action mapped in keymap is valid and recognized by Zed."""
    invalid_actions = []
    for block in keymap:
        for key, action in block.get("bindings", {}).items():
            if action is None:
                continue
            action_name = action
            if isinstance(action, list):
                action_name = action[0]
            if action_name == "task::Spawn":
                continue
            if action_name not in VALID_ACTIONS:
                invalid_actions.append((key, action_name, block.get("context")))
    assert not invalid_actions, f"Found invalid Zed actions: {invalid_actions}"


# ==============================================================================
# Seam 2: Neovim Feature Parity Coverage
# ==============================================================================
def test_vim_tmux_pane_navigation(keymap):
    workspace = _get_bindings_by_context(keymap, "Workspace")
    assert workspace.get("ctrl-h") == ["workspace::ActivatePaneInDirection", "Left"]
    assert workspace.get("ctrl-l") == ["workspace::ActivatePaneInDirection", "Right"]
    assert workspace.get("ctrl-k") == ["workspace::ActivatePaneInDirection", "Up"]
    assert workspace.get("ctrl-j") == ["workspace::ActivatePaneInDirection", "Down"]


def test_which_key_space_unbound(keymap):
    vim_control = _get_bindings_by_context(keymap, "VimControl")
    assert vim_control.get("space") is None, "space must be unbound (null) to prevent chord timeout"


def test_file_tree_normal_mode(keymap):
    panel = _get_bindings_by_context(keymap, "ProjectPanel")
    assert panel.get("j") == "menu::SelectNext"
    assert panel.get("k") == "menu::SelectPrev"
    assert panel.get("h") == "project_panel::CollapseSelectedEntry"
    assert panel.get("l") == "project_panel::ExpandSelectedEntry"
    assert panel.get("o") == "project_panel::Open"
    assert panel.get("enter") == "project_panel::Open"
    assert panel.get("q") == "project_panel::ToggleFocus"


def test_explorer_navigation_with_ctrl_l(keymap):
    # From Editor, ctrl-l navigates into the project panel (explorer)
    editor = _get_bindings_by_context(keymap, "Editor && (vim_mode == normal || vim_mode == visual)")
    assert editor.get("ctrl-l") == "project_panel::ToggleFocus"

    # From ProjectPanel, ctrl-h and ctrl-l return focus to the editor
    panel = _get_bindings_by_context(keymap, "ProjectPanel")
    assert panel.get("ctrl-h") == "workspace::FocusCenterPane"
    assert panel.get("ctrl-l") == "workspace::FocusCenterPane"


def test_editor_leader_window_splits(keymap):
    editor = _get_bindings_by_context(keymap, "Editor && (vim_mode == normal || vim_mode == visual)")
    assert editor.get("space v") == "pane::SplitRight"
    assert editor.get("space -") == "pane::SplitDown"
    assert editor.get("space q") == "pane::CloseActiveItem"
    assert editor.get("space c") == "workspace::NewFile"
    assert editor.get("space b n") == "pane::ActivateNextItem"
    assert editor.get("space b p") == "pane::ActivatePrevItem"


def test_editor_leader_tabs(keymap):
    editor = _get_bindings_by_context(keymap, "Editor && (vim_mode == normal || vim_mode == visual)")
    assert editor.get("space t t") == "workspace::NewFile"
    assert editor.get("space t c") == "pane::CloseActiveItem"
    assert editor.get("space t o") == "pane::CloseInactiveItems"
    assert editor.get("space t n") == "pane::ActivateNextItem"
    assert editor.get("space t p") == "pane::ActivatePrevItem"


def test_editor_leader_search_and_finder(keymap):
    editor = _get_bindings_by_context(keymap, "Editor && (vim_mode == normal || vim_mode == visual)")
    assert editor.get("space f f") == "file_finder::Toggle"
    assert editor.get("space f s") == "pane::DeploySearch"
    assert editor.get("space n h") == "editor::Cancel"
    assert editor.get("space e") == "project_panel::ToggleFocus"


def test_editor_lsp_navigation(keymap):
    editor = _get_bindings_by_context(keymap, "Editor && (vim_mode == normal || vim_mode == visual)")
    assert editor.get("g d") == "editor::GoToDefinition"
    assert editor.get("g D") == "editor::GoToDefinitionSplit"
    assert editor.get("g r") == "editor::FindAllReferences"
    assert editor.get("g i") == "editor::GoToImplementation"
    assert editor.get("g I") == "editor::GoToImplementationSplit"
    assert editor.get("g y") == "editor::GoToTypeDefinition"
    assert editor.get("K") == "editor::Hover"
    assert editor.get("space r n") == "editor::Rename"
    assert editor.get("space c a") == "editor::ToggleCodeActions"
    assert editor.get("g l") == "editor::Hover"


def test_editor_diagnostics(keymap):
    editor = _get_bindings_by_context(keymap, "Editor && (vim_mode == normal || vim_mode == visual)")
    assert editor.get("] d") == "editor::GoToDiagnostic"
    assert editor.get("[ d") == "editor::GoToPrevDiagnostic"
    assert editor.get("] e") == ["editor::GoToDiagnostic", {"severity": "error"}]
    assert editor.get("[ e") == ["editor::GoToPrevDiagnostic", {"severity": "error"}]
    assert editor.get("] w") == ["editor::GoToDiagnostic", {"severity": "warning"}]
    assert editor.get("[ w") == ["editor::GoToPrevDiagnostic", {"severity": "warning"}]
    assert editor.get("space x x") == "diagnostics::Deploy"


def test_editor_symbols(keymap):
    editor = _get_bindings_by_context(keymap, "Editor && (vim_mode == normal || vim_mode == visual)")
    assert editor.get("s s") == "outline::Toggle"
    assert editor.get("s S") == "project_symbols::Toggle"


def test_editor_formatting_and_preview(keymap):
    editor = _get_bindings_by_context(keymap, "Editor && (vim_mode == normal || vim_mode == visual)")
    assert editor.get("space t f") == "editor::Format"
    assert editor.get("space c f") == "editor::Format"
    assert editor.get("space m p") == "markdown::OpenPreviewToTheSide"


def test_editor_ai_integration(keymap):
    editor = _get_bindings_by_context(keymap, "Editor && (vim_mode == normal || vim_mode == visual)")
    assert editor.get("space a i") == "assistant::InlineAssist"
    assert editor.get("space a c") == "assistant::ToggleFocus"


def test_editor_harpoon(keymap):
    editor = _get_bindings_by_context(keymap, "Editor && (vim_mode == normal || vim_mode == visual)")
    assert editor.get("space a") == "pane::TogglePinTab"
    assert editor.get("space h a") == "pane::TogglePinTab"
    assert editor.get("ctrl-e") == "tab_switcher::Toggle"
    assert editor.get("space h h") == "tab_switcher::Toggle"
    assert editor.get("space 1") == ["pane::ActivateItem", 0]
    assert editor.get("space 2") == ["pane::ActivateItem", 1]
    assert editor.get("space 3") == ["pane::ActivateItem", 2]
    assert editor.get("space 4") == ["pane::ActivateItem", 3]
    assert editor.get("space h n") == "pane::ActivateNextItem"
    assert editor.get("space h p") == "pane::ActivatePrevItem"


# ==============================================================================
# Seam 3: Settings & Runtime Configuration
# ==============================================================================
def test_settings_core(settings):
    assert settings.get("vim_mode") is True
    assert settings.get("relative_line_numbers") == "enabled"
    assert settings.get("tab_size") == 4
    assert settings.get("hard_tabs") is False
    assert settings.get("diff_view_style") == "split"
    assert settings.get("format_on_save") == "on"
    assert settings.get("vim", {}).get("use_system_clipboard") == "on_yank"
    which_key = settings.get("which_key", {})
    assert which_key.get("enabled") is True
    assert which_key.get("delay_ms", 1000) <= 300


def test_settings_languages_lsp(settings):
    langs = settings.get("languages", {})
    assert "roslyn" in langs.get("CSharp", {}).get("language_servers", [])
    assert "pyright" in langs.get("Python", {}).get("language_servers", [])
    assert "gopls" in langs.get("Go", {}).get("language_servers", [])


# ==============================================================================
# Seam 4: Tasks Integrity
# ==============================================================================
def test_tasks_commands(tasks):
    labels = {t.get("label"): t for t in tasks}
    assert "Lazygit" in labels
    assert "dotnet test" in labels
    assert "dotnet run" in labels
    assert "dotnet watch" in labels


# ==============================================================================
# Seam 5: Sync Integrity
# ==============================================================================
def test_sync_windows_runtime():
    for filename in ["settings.json", "keymap.json", "tasks.json"]:
        source = os.path.join(ZED_DIR, filename)
        target = os.path.join(WIN_ROAMING_DIR, filename)
        assert os.path.exists(target), f"Missing target file: {target}"
        with open(source, "r", encoding="utf-8") as sf, open(target, "r", encoding="utf-8") as tf:
            assert sf.read() == tf.read(), f"File mismatch between {source} and {target}"


def test_sync_wsl_symlinks():
    for filename in ["settings.json", "keymap.json", "tasks.json"]:
        target = os.path.join(WSL_CONFIG_DIR, filename)
        assert os.path.islink(target), f"WSL config must be symlink: {target}"
        assert os.path.exists(target), f"WSL symlink broken: {target}"
