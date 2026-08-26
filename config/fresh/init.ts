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

