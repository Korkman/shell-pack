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

function shellpack_toggle_selection_mode() :void {
  if (editor.getEditorMode() === SELECTION_MODE) {
    editor.setEditorMode(null);
    editor.setStatus("");
  } else {
    editor.setEditorMode(SELECTION_MODE);
    editor.setStatus("-- SELECT --");
  }
};

function shellpackExitSelectionModeIfActive() : void {
  if (editor.getEditorMode() === SELECTION_MODE) {
    editor.setEditorMode(null);
    editor.setStatus("");
  }
}

function shellpack_copy_and_exit_selection() : void {
  editor.executeAction("copy");
  shellpackExitSelectionModeIfActive();
};

registerHandler("shellpack_toggle_selection_mode", shellpack_toggle_selection_mode);
registerHandler("shellpack_copy_and_exit_selection", shellpack_copy_and_exit_selection);

// cut, paste, typing, etc. all change buffer content one way or another -
// exit selection mode on any actual edit, same as cut/copy would in most
// other editors, instead of enumerating every mutating action/keybinding.
editor.on("after_insert", shellpackExitSelectionModeIfActive);
editor.on("after_delete", shellpackExitSelectionModeIfActive);

// selection mode is scoped to a single buffer view - switching tabs/buffers
// should not leave it active over whatever buffer the user lands on next.
editor.on("buffer_activated", shellpackExitSelectionModeIfActive);
editor.on("buffer_deactivated", shellpackExitSelectionModeIfActive);

// there's no bindKey/unbindKey API to attach ctrl-w to close_tab only on
// non-terminal buffers, so ctrl-w is bound statically (config.json) to this
// handler, which queries the active buffer's terminal-ness and only closes the
// tab when it's not a terminal - leaves terminal buffers' own ctrl-w behavior
// (readline word-delete, etc.) untouched.
function shellpack_close_tab_if_not_term() : void {
  const bufferId = editor.getActiveBufferId();
  const info = editor.getBufferInfo(bufferId);
  if (!info.is_terminal) {
    editor.executeAction("close_tab");
  }
};

registerHandler("shellpack_close_tab_if_not_term", shellpack_close_tab_if_not_term);
// to be actually available, we must use editor.registerCommand, which also makes the function visible in palette
editor.registerCommand("Close tab if not terminal", "Closes tab if not terminal", "shellpack_close_tab_if_not_term");
