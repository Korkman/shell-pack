function __sp_cheat_fresh
	echo "
fresh editor
(as configured by shell-pack)

navigation:
  Ctrl-L, Alt-L, Ctrl-G: go to line
  Ctrl-Left, Ctrl-Right: move cursor by words
  Ctrl-Home, Ctrl-End: start / end of file
  Home, End: start / end of line
  PageUp, PageDown: scroll page up / down
  Alt-Up, Alt-Down: move line / selection up / down
  Alt-Left, Alt-Right: navigation history

search & replace:
  Ctrl-F, F7: search / find in file
  F3, Alt-N: find next match
  Shift-F3, Alt-Shift-N, Alt-P: find previous match
  Ctrl-R, Ctrl-H, F4: query replace

editing:
  Ctrl-S, F2: save file
  Ctrl-Z, Ctrl-Y: undo / redo
  Ctrl-C, Ctrl-V, Ctrl-X: copy, paste, cut
  F5: copy
  Ctrl-D: duplicate line
  F8: delete line (or active selection)
  Ctrl-K /, Ctrl-/: toggle line / selection comment
  Tab, Shift-Tab, Ctrl-K Tab: indent / dedent selection

selection mode:
  Alt-Space, Alt-Y: toggle selection mode (-- SELECT --)
    Arrows, PgUp, PgDn: expand selection
    Ctrl-Left, Ctrl-Right: expand by word
    Alt-Arrows, Alt-h/j/k/l: block (column / rectangular) selection
    Ctrl-C, F5: copy selection and exit mode
    Esc, Alt-Space, Alt-Y: exit selection mode
  Shift-Arrows: standard text selection
  Esc: dismiss secondary cursors, or quit

tabs, buffers & terminal:
  Ctrl-O: open file
  Ctrl-Alt-O: quick open file (recursive file finder)
  Alt-T: switch tab by name
  Ctrl-P: palette with prefixes:
         > commands (initial default)
    (none) quick open file (recursive file finder)
         # switch tabs
         : goto line
  Ctrl-T: new terminal tab
  Ctrl-W: close tab ('delete word' in terminal tabs)
  Ctrl-K Left, Ctrl-K Right: switch to previous / next buffer

panels & UI:
  Ctrl-E, Ctrl-B: toggle / focus file explorer
  Alt-O: toggle orchestrator dock
  F9: activate menu bar
  Ctrl-',', Ctrl-K ',': open settings
  Ctrl-K Ctrl-S: open keybinding editor
  Ctrl-K M: set syntax language

quit:
  Esc, F10, Alt-Q, Ctrl-Q: quit editor
  Alt-Shift-Q: force quit without prompt (will restore)
  Ctrl-K D: detach when started as daemon

CLI & remote usage:
  fresh file:12                 open at line 12
  fresh file:10-25              open with lines 10 to 25 selected
  fresh -a [NAME]               create / attach to detachable daemon (background session)
  fresh user@host:path          edit remote file over SSH
" | __sp_pager --prompt "cheat --fresh | less - q to quit, h for help"
end

