// shell-pack config preset

// declaring "editor" so IDEs don't throw errors
declare const editor: any;

// LC_NERDLEVEL 3 indicates nerd font is installed in the terminal emulator
if (editor.getEnv("LC_NERDLEVEL") === "3") {
  editor.setSetting("editor.nerd_font_icons", true);
} else {
  editor.setSetting("editor.nerd_font_icons", false);
}

// fall back to a high-contrast theme when the terminal lacks 256-color support
if (!(editor.getEnv("TERM") ?? "").endsWith("-256color")) {
  editor.setSetting("theme", "high-contrast");
}

// "selection mode": alt-space starts a selection, plain arrow keys then
// expand it, alt-space/escape again ends it. Uses defineMode/setEditorMode
// (like the bundled vi plugin's insert/normal toggle) rather than
// setContext + "when" keybindings - those consistently failed to resolve
// plugin actions as global functions.
const SELECTION_MODE = "shellpack-select";

editor.defineMode(
  SELECTION_MODE,
  [
    ["up", "select_up"],
    ["down", "select_down"],
    ["left", "select_left"],
    ["right", "select_right"],
    ["C-Left", "select_word_left"],
    ["C-Right", "select_word_right"],
    ["M-Left", "select_word_left"],
    ["M-Right", "select_word_right"],
    ["escape", "shellpack_toggle_selection_mode"],
    // copying the selection is the natural end of a select-then-expand flow
    ["C-c", "shellpack_copy_and_exit_selection"],
    ["F5", "shellpack_copy_and_exit_selection"],
  ],
  false, // readOnly
  false, // allowTextInput
  true, // inheritNormalBindings - everything else behaves as normal
);

(globalThis as any).shellpack_toggle_selection_mode = function () {
  if (editor.getEditorMode() === SELECTION_MODE) {
    editor.setEditorMode(null);
    editor.setStatus("");
  } else {
    editor.setEditorMode(SELECTION_MODE);
    editor.setStatus("-- SELECT --");
  }
};

function shellpackExitSelectionModeIfActive() {
  if (editor.getEditorMode() === SELECTION_MODE) {
    editor.setEditorMode(null);
    editor.setStatus("");
  }
}

(globalThis as any).shellpack_copy_and_exit_selection = function () {
  editor.executeAction("copy");
  shellpackExitSelectionModeIfActive();
};

registerHandler("shellpack_toggle_selection_mode", (globalThis as any).shellpack_toggle_selection_mode);
registerHandler("shellpack_copy_and_exit_selection", (globalThis as any).shellpack_copy_and_exit_selection);

// cut, paste, typing, etc. all change buffer content one way or another -
// exit selection mode on any actual edit, same as cut/copy would in most
// other editors, instead of enumerating every mutating action/keybinding.
editor.on("after_insert", shellpackExitSelectionModeIfActive);
editor.on("after_delete", shellpackExitSelectionModeIfActive);

// selection mode is scoped to a single buffer view - switching tabs/buffers
// should not leave it active over whatever buffer the user lands on next.
editor.on("buffer_activated", shellpackExitSelectionModeIfActive);
editor.on("buffer_deactivated", shellpackExitSelectionModeIfActive);

editor.on("after_copy", shellpackExitSelectionModeIfActive);
