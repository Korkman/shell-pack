function __sp_cheat_mc
	echo "
midnight commander
(as configured by shell-pack)

global keys:

Alt-Q, Alt-Shift-Q, Alt-Shift-W:
  mc has multiple windows. when internal editors are opened, use these to switch
  between them and the file manager.

mcedit (partially also mcview):

  Ctrl-C, Ctrl-V, Ctrl-X: copy, paste and cut (file backed clipboard)
  Ctrl-Z, Ctrl-Y, Ctrl-Shift-Z: undo / redo
  Ctrl-S, F2: save file
  Ctrl-F, F7: find in file
  Alt-N, Shift-F7: continue search
  Ctrl-L, Alt-L: goto line in mcedit
  Ctrl-Left, Ctrl-Right: move cursor by words
  Ctrl-W: closes the editor
  Tab, Esc & Tab: indent, unindent selection
  Shift-Arrows: select text

mcdiff:
  Alt-Down, Alt-Up: go to next / previous hunk
  Alt-Left, Alt-Right: merge hunk into left / right file
  F4: edit left file
  Shift-F4: edit right file

file manager:
  Alt-Enter: inserts selected filename into subshell
  Alt-S: prefix search in file listing, syntax highlighting in mcedit
  Alt-D: show bookmarks list (including shell-pack tagged dirs)
  Arrows: navigate (lynx-like motion enabled)
" | __sp_pager --prompt "cheat --mc | less - q to quit, h for help"
end
