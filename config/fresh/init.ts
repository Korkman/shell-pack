// shell-pack config preset

// declaring "editor" so IDEs don't throw errors
declare const editor: any;

// nerd fonts only render correctly when LC_NERDLEVEL is set to 3
if (editor.getEnv("LC_NERDLEVEL") === "3") {
  editor.setSetting("editor.nerd_font_icons", true);
} else {
  editor.setSetting("editor.nerd_font_icons", false);
}
