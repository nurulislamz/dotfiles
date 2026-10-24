#!/usr/bin/env python3
"""Zed JSON + keymap contracts. Host sync lives in test/live/zed_sync.py."""

from pathlib import Path
import json
import unittest

ROOT = Path(__file__).resolve().parents[1]
ZED = ROOT / "zed"

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
    "editor::GoToPreviousDiagnostic",
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


def _bindings(keymap, context_substr):
    for block in keymap:
        if context_substr in block.get("context", ""):
            return block.get("bindings", {})
    return {}


class ZedConfigTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.settings = json.loads((ZED / "settings.json").read_text(encoding="utf-8"))
        cls.keymap = json.loads((ZED / "keymap.json").read_text(encoding="utf-8"))
        cls.tasks = json.loads((ZED / "tasks.json").read_text(encoding="utf-8"))

    def test_all_actions_valid(self):
        invalid = []
        for block in self.keymap:
            for key, action in block.get("bindings", {}).items():
                if action is None:
                    continue
                name = action[0] if isinstance(action, list) else action
                if name == "task::Spawn":
                    continue
                if name not in VALID_ACTIONS:
                    invalid.append((key, name, block.get("context")))
        self.assertEqual(invalid, [])

    def test_vim_tmux_pane_navigation(self):
        workspace = _bindings(self.keymap, "Workspace")
        self.assertEqual(workspace.get("ctrl-h"), ["workspace::ActivatePaneInDirection", "Left"])
        self.assertEqual(workspace.get("ctrl-l"), ["workspace::ActivatePaneInDirection", "Right"])
        self.assertEqual(workspace.get("ctrl-k"), ["workspace::ActivatePaneInDirection", "Up"])
        self.assertEqual(workspace.get("ctrl-j"), ["workspace::ActivatePaneInDirection", "Down"])

    def test_which_key_space_unbound(self):
        self.assertIsNone(_bindings(self.keymap, "VimControl").get("space"))

    def test_file_tree_normal_mode(self):
        panel = _bindings(self.keymap, "ProjectPanel")
        self.assertEqual(panel.get("j"), "menu::SelectNext")
        self.assertEqual(panel.get("k"), "menu::SelectPrev")
        self.assertEqual(panel.get("h"), "project_panel::CollapseSelectedEntry")
        self.assertEqual(panel.get("l"), "project_panel::ExpandSelectedEntry")
        self.assertEqual(panel.get("o"), "project_panel::Open")
        self.assertEqual(panel.get("enter"), "project_panel::Open")
        self.assertEqual(panel.get("q"), "project_panel::ToggleFocus")

    def test_editor_leader_and_lsp(self):
        editor = _bindings(self.keymap, "Editor && (vim_mode == normal || vim_mode == visual)")
        self.assertEqual(editor.get("space v"), "pane::SplitRight")
        self.assertEqual(editor.get("space f f"), "file_finder::Toggle")
        self.assertEqual(editor.get("g d"), "editor::GoToDefinition")
        self.assertEqual(editor.get("g r"), "editor::FindAllReferences")
        self.assertEqual(editor.get("space e"), "project_panel::ToggleFocus")

    def test_settings_core(self):
        self.assertTrue(self.settings.get("vim_mode"))
        self.assertEqual(self.settings.get("relative_line_numbers"), "enabled")
        self.assertEqual(self.settings.get("tab_size"), 4)
        self.assertIs(self.settings.get("hard_tabs"), False)
        self.assertEqual(self.settings.get("diff_view_style"), "split")
        self.assertEqual(self.settings.get("format_on_save"), "on")
        self.assertEqual(self.settings.get("vim", {}).get("use_system_clipboard"), "on_yank")
        which_key = self.settings.get("which_key", {})
        self.assertTrue(which_key.get("enabled"))
        self.assertLessEqual(which_key.get("delay_ms", 1000), 300)

    def test_settings_languages_lsp(self):
        langs = self.settings.get("languages", {})
        self.assertIn("roslyn", langs.get("CSharp", {}).get("language_servers", []))
        self.assertIn("pyright", langs.get("Python", {}).get("language_servers", []))
        self.assertIn("gopls", langs.get("Go", {}).get("language_servers", []))

    def test_tasks_commands(self):
        labels = {t.get("label") for t in self.tasks}
        for name in ("Lazygit", "dotnet test", "dotnet run", "dotnet watch"):
            self.assertIn(name, labels)


if __name__ == "__main__":
    unittest.main()
