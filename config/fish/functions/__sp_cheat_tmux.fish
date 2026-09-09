function __sp_cheat_tmux
	echo "
TMUX AS CONFIGURED BY SHELL-PACK
 
# THE STATUS BAR
 
left side:
  mode indicator (hidden when tight):
    NORM: normal input
    COPY: copy-mode active (scrolled, selected text)
    PRFX: prefix active (ctrl-a was pressed)
    SYNC: input is mirrored to all panes (ctrl-a shift-b)
  user@hostname
  session name
 
center: window tabs
  1:tab = the first tab (ctrl-a 1)
  tab* = the current tab
  tab- = the previous tab (ctrl-a ctrl-a)
  !tab = a bell was recorded in the tab
  tab# = activity monitor triggered (ctrl-a shift-m)
  tab~ = silence monitor triggered (ctrl-a _)
  
right side:
  load average (hidden when tight)
  clock
  date (hidden when tight)
 
# THE KEYBOARD
 
ctrl-a: is an alias for ctrl-b because it is more accessible (and tradition)
ctrl-a, lift keys, then
  f1: show this help
    alias: h
  d: detach session, leaving it running in background
  r: reload config
  c: create new window
  1-9,0: jump to window number 1-10
  backspace, space: jump to previous, next window
  ctrl-a: jump to most recent window
  arrow-left, arrow-right: move window left / right on status bar (may renumber)
  shift-A: rename window
  shift-N: show window number and name
  shift-M: monitor window for activity (once)
  _: monitor window for silence (once)
  esc: enter copy-mode (scroll up to 50000 lines in history)
    alias: up, pgup, mouse-wheel-up, immediately scroll up
    alias: y, alt-up, will immediately scroll to previous prompt
    alias: alt-pgup, scroll to start of history
    in copy-mode:
      mouse: supports drag, double- and tripleclick to copy
      space: start
      enter: copy & leave copy-mode
      c: copy selection, stay in copy-mode
      C: clear selection, stay in copy-mode
      y / x / alt-up / alt-down: scroll to previous / next prompt
      alt-pgup / alt-pgdn: scroll to start / end of history
  v: paste previously copied text
  |: split window into panes left and right
  -: split window into panes top and bottom
     alias: shift-S
  tab: jump to next pane
  ctrl-arrows: resize current pane
  k: kill pane (if confirmed)
  m: mark pane
  s: swap pane with marked
  shift-B: toggle broadcast mode, sending keystrokes to all panes in window
  w: show sessions and their windows
  shift-W: move window to other session with picker
  alt-w: move window to (new) other session
  shift-Q: break out a pane into a dedicated window
    alias: !
  shift-K: kill all windows and exit (if confirmed)
    alias: \
  alt-l: cycle through left status styles
  alt-r: cycle through right status styles
  alt-z: collapse both left and right status
  alt-t: move status to top
  alt-b: move status to bottom
 
# THE MOUSE
 
- scroll or drag in pane immediately enters copy-mode
- selection is copied to tmux clipboard and terminal host if supported
- selection does not exit copy-mode to accomodate copying multiple strings
- (alt-)right-click context menus are available from tmux
- click left status to toggle left status styles
- alt-click left status shows session tree chooser
- prefix + wheelup/-down on left status moves status bar to top / bottom
- double-click on tab renames window
- alt-double-click on tab creates new window next to it
- button 2 on tab closes window with confirm
- prefix + button 2 on tab closes window without confirm
- click right status to toggle right status styles
- alt-click right status to run dool + htop in new windows
- double-click in empty area to create new window at end
- wheelup/-down on status switches through tabs
 
# FURTHER NOTES
 
- window numbering starts at 1, ends on 0 to be more natural on keyboard
- environment variables are being taken care of
  - most notably enabling ssh agent forwarding
- a new window will inherit the working directory of the foreground process
- 'ctrl-a, :' enters command mode
  - run 'list-keys' to see all built-in and configured keybinds
  - run 'list-commands' for all available commands
" | __sp_pager --prompt "cheat --tmux | less - q to quit, h for help"
end
