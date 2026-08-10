function cheat
	if [ "$argv[1]" = "--help" ]
		# --help always shows the shell-pack cheatsheet, bypassing any native 'cheat' command
		set argv[1] --shell-pack
	end

	if [ "$argv[1]" = "--glyphs" ]
		__cheat_glyphs
		return
	end

	if [ "$argv[1]" = "--colors" ] || [ "$argv[1]" = "--colours" ]
		__cheat_colors
		return
	end

	if [ "$argv[1]" = "--mc" ]
		__cheat_mc
		return
	end

	if [ "$argv[1]" = "--tmux" ]
		__cheat_tmux
		return
	end

	if [ "$argv[1]" = "--fzf-query" ]
		__cheat_fzf_query
		return
	end

	if [ "$argv[1]" = "--chtsh" ]
		set -e argv[1]
		if test -z "$argv[1]"
			dl --cache=7d --cache-allow-stale --silent https://cheat.sh | __sp_pager -R
		else
			dl --cache=7d --cache-allow-stale --silent https://cheat.sh/$argv[1] | __sp_pager -R
		end
		return
	end

	# prefer native cheat command if installed
	if command -v cheat > /dev/null && [ "$argv[1]" != "--shell-pack" ]
		command cheat $argv
		if [ "$argv[1]" = "" ]
			echo
			echo "  To view the native shell-pack cheatsheet:"
			echo "    cheat --shell-pack"
			echo "    (shell-pack detected 'cheat' is installed)"
		end
		return
	else if ! test -z "$argv[1]" && test "$argv[1]" != "--shell-pack" && test "$argv[1]" != "--help"
		cheat --chtsh $argv
		return
	end

	echo "
Shell-pack "(shell-pack-version)" integrated cheat sheets and cht.sh client

========= Cheat sheets =========

Show this cheatsheet          cheat
Show glyphs cheatsheet        cheat --glyphs
Show mc cheatsheet            cheat --mc
Show tmux cheatsheet          cheat --tmux
Show fzf query syntax         cheat --fzf-query
Show 256-color chart          cheat --colors (--colours)
Query cheat.sh for TOPIC      cheat TOPIC
  More information            cheat --chtsh
Show this help                cheat --help


========= Keymappings =========

Command History
---------------
Prefix search in history      Up
Delete selected history item  F8
Delete & edit last command    F4
Accept autosuggestion         End               Right
... partially                 Ctrl-Right
Fuzzy search in history       Ctrl-R
Search args history           Alt-.
... reverse direction         Alt-,
Fiddle mode                   F11

Change directory
----------------
cd ..                         Shift-Up          Alt-Up
cd ~ | cd /                   Alt-Home
Change directory              Shift-Down        Alt-Down       Alt-X
... excluding dotfiles        Alt-Shift-Down    Alt-Shift-X
... recursive                 Alt-C
... recursive - dotfiles      Alt-Shift-C
Navigate back                 Shift-Left        Alt-Left       Alt-Y
Navigate forward              Shift-Right       Alt-Right      Alt-Shift-Y
List tagged dirs              Alt-D

Search files
------------
Search by filename            Alt-F             Ctrl-F
... excl. dotfiles            Alt-Shift-F       Ctrl-T
Search by contents (regex)    Alt-G             Ctrl-G

Other
-----
Autocomplete                  Tab
Autocomplete arguments        - & Tab
Find in autocomplete          Ctrl-F            Ctrl-S
Append '&| less'              Alt-P
Prepend 'sudo'                Alt-S
Manpage for current cmd       Alt-H             F1
What is word at cursor        Alt-W
Edit commandline in \$EDITOR   Alt-E
Clear line, exit shell        F10


========= Quick commands =========

Launch POSIX-compliant shell  oldshell

Change LC_NERDLEVEL           nerdlevel LEVEL
  0 No fish (run $OLDSHELL)
  1 No font
  2 Powerline font
  3 Nerdfont

Reload FISH                   reload

Tag session (tab title)       tag TITLE
Untag session                 untag

Tag current directory         tagdir NAME
Untag current directory       untagdir
... specified directory       untagdir [ NAME | PATH ]
List tagged directories       lsdirtags

Search files for content       rrg REGEX
... pass rg options            rrg --option ... -- REGEX
... see also                   rrg-help
Search in file for content     rrg-in-file -f FILE REGEX

(Re)open tmux / screen
  for user X                  $__multiplexer_names
  exclusive session 'one'     one
  steal session 'one'         forceone
  share session 'one'         shareone
  custom session              mmux SESSION [ ... see usage ]

Execute commandline at time   @ 'TIME' ... | ...

Toggle full private mode      private
- no history read / written
- toggle again to exit shell

========== utilities ==========

Grasp a stream or file with fzf    grasp CMD [ ARGS ]
Use fzf as pager                   ppage CMD [ ARGS ]
List ssh fingerprints              ffingerprints [ host [ port ] ]
List open network ports            lsports
List established connections       lsnet
dool with saved preset             ddool
  (formerly: dstat, ddstat)
SMART readout from /dev/NAME       ssmart NAME

mount /dev/NAME /run/q/NAME        qmount NAME
  ex. NAME for /dev/sda: sda
  ex. NAME for LVM: vg/lv
umount /run/q/NAME                 qumount NAME

mount --rbind /dev, /proc, /sys    qchroot [ OPTS.. ] [ DIR [ CMD [ ARGS ] ] ]
  into DIRECTORY, then chroot,
  then umount on exit

Fetch man page from internet       onman [ SECTION ] PAGE
Download with curl or wget         dl URL [ FILENAME ]
Compressed file creation           cfc FILE|DIR [ FILE|ALGO ]
Compressed file decompression      cfd FILE [ DESTINATION ]
Copy to client clipboard           cclip FILE
SSH, but managed                   qssh [ ssh-params ]
git add + commit with review       ggit
Create and edit a template         create [ bash | fish | service | ... ] FILE
Encrypt a file                     qcrypt -e [--gpg] FILE OUTFILE
Decrypt a stream                   cat data | qcrypt -d [--gpg] | cat

	" | __sp_pager -P "cheat --shell-pack | less - q to quit, h for help" '+G' '+g'
end

function __cheat_glyphs
	set -l pl_a1 (set_color 711)""(set_color -b 711)" "(set_color normal; set_color 711)""(set_color normal)
	set -l pl_a2 (set_color 171)""(set_color -b 171)" "(set_color normal; set_color 171)""(set_color normal)
	set -l pl_a3 (set_color yellow)""(set_color -b yellow)" "(set_color normal; set_color yellow)""(set_color normal)
	set -l policeline (set_color ff0)""(set_color normal)
	set -l style_b (echo -e '\e[1mBold\e[0m')
	set -l style_i (echo -e '\e[3mItalic\e[0m')
	set -l style_u (echo -e '\e[4mUnderline\e[0m')
	set -l style_s (echo -e '\e[9mStrike\e[0m')
	echo -n "Terminal glyphs and capabilities test:

   ┌──────────────────────────┐
  │ Powerline Solid Arrow    └── This line must appear solid! (mc)
  │ Powerline Hollow Arrow   
  │ Read-only lock          🠴 UTF8 7.0 'Finger-Post' Arrows 🠶
  │ Bookmark                
  │ Debian Swirl Logo       Batteries at 10, 50, 100%, charging: 󰢜 󰢝 󰂅
  │ Exit Error                                     not charging: 󰁺 󰁾 󰁹
 󰋞 │ Home                     
  │ Hourglass End           Styles: $style_i, $style_s, $style_b and $style_u
  │ Exit OK                  
  │ Walking man             Powerlines: $pl_a1 $pl_a2 $pl_a3
 ↓ │ Arrow Down (mc)                     Disrupted? Adjust font size.
  │ Calendar                 
 ✕ │ Close X (mc)            Policeline: $policeline 
───┘   
 __ Glyphs must not be cut off - some symbols may be as wide as these two
    underscores! If they don't, your font is monospace, which is wrong.

Are these color gradients fine?
"
	# red
	for i in 4 7 a c e
		set_color -b "$i""$i"0000
		echo -n "  "
	end
	for j in 3 7 a c e f
		set_color -b ff"$j""$j""$j""$j"
		echo -n "  "
	end
	set_color normal
	#echo
	# yellow
	for i in 4 7 a c e
		set_color -b "$i""$i""$i""$i"00
		echo -n "  "
	end
	for j in 3 7 a c e f
		set_color -b ffff"$j""$j"
		echo -n "  "
	end
	set_color normal
	#echo
	# green
	for i in 4 7 a c e
		set_color -b 00"$i""$i"00
		echo -n "  "
	end
	for j in 3 7 a c e f
		set_color -b "$j""$j"ff"$j""$j"
		echo -n "  "
	end
	set_color normal
	echo
	# cyan
	for i in 4 7 a c e
		set_color -b 00"$i""$i""$i""$i"
		echo -n "  "
	end
	for j in 3 7 a c e f
		set_color -b "$j""$j"ffff
		echo -n "  "
	end
	set_color normal
	#echo
	# blue
	for i in 4 7 a c e
		set_color -b 0000"$i""$i"
		echo -n "  "
	end
	for j in 3 7 a c e f
		set_color -b "$j""$j""$j""$j"ff
		echo -n "  "
	end
	set_color normal
	#echo
	# magenta
	for i in 4 7 a c e
		set_color -b "$i""$i"00"$i""$i"
		echo -n "  "
	end
	for j in 3 7 a c e f
		set_color -b ff"$j""$j"ff
		echo -n "  "
	end
	set_color normal
	echo
end

function __cheat_color_fg
	# picks black (30) or bright white (97) foreground for readability on the given rgb background
	set -l r $argv[1]
	set -l g $argv[2]
	set -l b $argv[3]
	set -l luma (math -s0 "0.299 * $r + 0.587 * $g + 0.114 * $b")
	if test $luma -gt 140
		echo 30
	else
		echo 97
	end
end

function __cheat_blocks_per_row
	# argv: block_width gap max_blocks block_count -> how many blocks fit on one terminal row
	set -l block_width $argv[1]
	set -l gap $argv[2]
	set -l max_blocks (math "min($argv[3], $argv[4])")
	set -l cols $COLUMNS
	if test -z "$cols"
		set cols 80
	end
	for n in (seq $max_blocks -1 1)
		if test (math "$n * $block_width + ($n - 1) * $gap") -le $cols
			echo $n
			return
		end
	end
	echo 1
end

function __cheat_colors
	begin
		echo "256-color terminal palette (index shown on each swatch)"
		echo
		echo "0-15: the 16 basic ANSI colors (terminal themes apply)"
		echo
		set -l basic_r 0 128 0 128 0 128 0 192 128 255 0 255 0 255 0 255
		set -l basic_g 0 0 128 128 0 0 128 192 128 0 255 255 0 0 255 255
		set -l basic_b 0 0 0 0 128 128 128 192 128 0 0 0 255 255 255 255
		for i in (seq 0 15)
			set -l fg (__cheat_color_fg $basic_r[(math "$i + 1")] $basic_g[(math "$i + 1")] $basic_b[(math "$i + 1")])
			printf "\e[48;5;%sm\e[%sm%4d\e[0m" $i $fg $i
			if test (math "($i + 1) % 8") -eq 0
				echo
			end
		end
		echo

		echo "16-231: 6x6x6 RGB color cubes (terminal themes usually don't apply)"
		echo
		set -l levels 0 95 135 175 215 255
		set -l cube_per_row (__cheat_blocks_per_row 24 3 3 6)
		for group_start in (seq 0 $cube_per_row 5)
			set -l group_end (math "min($group_start + $cube_per_row - 1, 5)")
			set -l reds (seq $group_start $group_end)
			for green in (seq 0 5)
				for red in $reds
					for blue in (seq 0 5)
						set -l i (math "16 + $red * 36 + $green * 6 + $blue")
						set -l fg (__cheat_color_fg $levels[(math "$red + 1")] $levels[(math "$green + 1")] $levels[(math "$blue + 1")])
						printf "\e[48;5;%sm\e[%sm%4d\e[0m" $i $fg $i
					end
					if test $red != $reds[-1]
						printf "   "
					end
				end
				echo
			end
			echo
		end

		echo "232-255: grayscale ramp, split into blocks of 6"
		echo
		set -l gray_per_row (__cheat_blocks_per_row 24 3 3 2)
		for group_start in (seq 0 $gray_per_row 1)
			set -l group_end (math "min($group_start + $gray_per_row - 1, 1)")
			set -l blocks (seq $group_start $group_end)
			for row in 0 1
				for block in $blocks
					set -l base (math "232 + $block * 12 + $row * 6")
					for i in (seq $base (math "$base + 5"))
						set -l gray (math "8 + 10 * ($i - 232)")
						set -l fg (__cheat_color_fg $gray $gray $gray)
						printf "\e[48;5;%sm\e[%sm%4d\e[0m" $i $fg $i
					end
					if test $block != $blocks[-1]
						printf "   "
					end
				end
				echo
			end
			echo
		end
	end | __sp_pager -P "cheat --colors | less - q to quit, h for help" '+G' '+g'
end

function __cheat_mc
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
" | __sp_pager -P "cheat --mc | less - q to quit, h for help" '+G' '+g'
end

function __cheat_tmux
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
" | __sp_pager -P "cheat --tmux | less - q to quit, h for help" '+G' '+g'
end

function __cheat_fzf_query
	echo "
fzf query syntax

Case-insensitive unless uppercase letters are used.

Token    Match type
─────    ──────────
sbtrkt   fuzzy match: contains chars in that order
         (--exact changes this to exact match)
'wild    exact match: contains 'wild'
         (--exact changes this to fuzzy match)
'wild'   exact word match: finds 'wild' as word
^music   prefix exact match: starts with 'music'
.mp3\$    suffix exact match: ends with '.mp3'
!fire    inverse exact match: does not contain 'fire'
!^music  inverse prefix match: does not start with 'music'
!.mp3\$   inverse suffix match: does not end with '.mp3'

Escape spaces with backslash:
  'foo\ bar   matches 'foo bar' exactly
  !foo\ bar   inverse exact match 'foo bar'

Combine tokens by separating with spaces (AND):
  ^core go\$     starts with 'core' AND ends with 'go'

Use | for OR:
  ^core | go\$   starts with 'core' OR ends with 'go'
" | __sp_pager -P "cheat --fzf-query | less - q to quit, h for help" '+G' '+g'
end
