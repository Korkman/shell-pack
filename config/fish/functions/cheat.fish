function cheat
	if [ "$argv[1]" = "--glyphs" ]
		__cheat_glyphs
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

	if command -v cheat > /dev/null && [ "$argv[1]" != "--shell-pack" ]
		command cheat $argv
		if [ "$argv[1]" = "" ]
			echo
			echo "  To view the native shell-pack cheatsheet:"
			echo "    cheat --shell-pack"
			echo "    (shell-pack detected 'cheat' is installed)"
		end
		return
	end
	
	

	echo "
Fish & shell-pack "(shell-pack-version)" cheatsheet

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
Edit commandline in \$EDITOR  Alt-E
Clear line, exit shell        F10


========= Quick commands =========

Show this cheatsheet          cheat
Show glyphs cheatsheet        cheat --glyphs
Show mc cheatsheet            cheat --mc
Show tmux cheatsheet          cheat --tmux

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

========== for admins ==========

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

Download with curl or wget         dl URL [ FILENAME ]
Compressed file creation           cfc FILE|DIR [ FILE|ALGO ]
Compressed file decompression      cfd FILE [ DESTINATION ]
SSH, but managed                   qssh [ ssh-params ]
git add + commit with review       ggit
create and edit a template         create [ bash | fish | service | ... ] FILE

	" | less -P "cheat --shell-pack | less - q to quit, h for help"
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
  │ Powerline Solid Arrow    └── This line is solid! (mc)
  │ Powerline Hollow Arrow
  │ Read-only lock
  │ Bookmark
 󰋞 │ Home
  │ Debian Swirl Logo     Styles: $style_i, $style_s, $style_b and $style_u
  │ Exit OK
  │ Exit Error            Powerlines: $pl_a1 $pl_a2 $pl_a3
  │ Hourglass End                     Disrupted? Adjust font size.
  │ Calendar
  │ Walking man           Policeline: $policeline
 ↓ │ Arrow Down (mc)
 ✕ │ Close X (mc)
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

function __cheat_mc
	echo "
midnight commander
(as configured by shell-pack)

global keys:

Alt-Q, Alt-Shift-Q, Alt-Shift-W:
  mc has multiple windows. when internal editors are opened, use these to switch
  between them and the file manager.

mcedit (partially also mcview):

Ctrl-C, Ctrl-V, Ctrl-X:
  these are bound now in mcedit and work as you'd expect for copy, paste and cut
Ctrl-Z, Ctrl-Y, Ctrl-Shift-Z:
  these, too, are bound now in mcedit and undo / redo respectively
Ctrl-S: in addition to F2, saves in mcedit
Ctrl-F: in addition to F7, search in mcedit
Alt-N: in addition to Shift-F7, continue search
Ctrl-L, Alt-L: goto line in mcedit
Ctrl-Left, Ctrl-Right: move cursor by words
Ctrl-W: closes the editor
Tab, Esc & Tab: indent, unindent selection
Shift-Arrows: Select text

file manager:
  Alt-Enter: inserts selected filename into subshell
  Alt-S: prefix search in file listing, syntax highlighting in mcedit
  Alt-D: show bookmarks list (including shell-pack tagged dirs)
" | less -P "cheat --mc | less - q to quit, h for help"
end

function __cheat_tmux
	echo "
tmux
(as configured by shell-pack)

keys:

ctrl-a: is synonym for ctrl-b, because it is more accessible (and tradition)
ctrl-a, lift keys, then
  r: reload config
  |: split window into left and right
  -: split window into top and bottom
    alias: shift-s
  c: create new window
  esc: enter copy-mode to scroll up to 50000 lines back
    alias: pgup, mouse-wheel-up
    alias: up, will also scroll to previous prompt
    alias: down, will also scroll to next prompt
    in copy-mode:
      space / enter: modify and copy selection
      alt-up / alt-down: scroll to previous / next prompt
  v: paste previoulsy copied text
  arrow-left, arrow-right: move window left / right on task bar, renumber
  shift-b: toggle broadcast mode, sending keystrokes to all panes
  backspace, space: jump to previous, next window
  ctrl-a: jump to most recent window
  shift-Q: break out a pane into a dedicated window
    alias: !
  k: kill pane (if confirmed)
  m: mark pane
  s: swap pane with marked
  tab: jump to next pane
  shift-k: kill all windows and exit (if confirmed)
    alias: \
  shift-n: show window number and name
  shift-a: rename window
  M: monitor window for activity (once)
	_: monitor window for silence (once)
ctrl-a, keep ctrl pressed, then
  arrows: resize current pane

notes:

* mouse works, can scroll in history when in copy mode and resize panes
* alt-right-click opens a context menu in recent tmux versions
* window numbering starts at 1, ends on 0 to be more natural on keyboard
* environment variables are being taken care of, most notably enabling 
  ssh agent forwarding
* a new window will inherit the working directory of the current window
" | less -P "cheat --tmux | less - q to quit, h for help"
end
