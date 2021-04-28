function cheat
	if [ "$argv[1]" = "--glyphs" ]
		__cheat_glyphs
		return
	end
	echo "
VB enhanced FISH "(shell-pack-version)" Cheatsheet

========= Keymappings =========

Command History
---------------
Prefix search in history      Up
Delete current history item   F8
Accept autosuggestion         End               Right
... partially                 Ctrl-Right
Fuzzy search in history       Ctrl-R
Search args history           Alt-.
... reverse direction         Alt-,

Change directory
----------------
cd ..                         Alt-Up
Navigate into subdirectory    Alt-Down          Alt-X
... excluding dotfiles        Alt-Shift-Down    Alt-Shift-X
... recursive                 Alt-C
... recursive - dotfiles      Alt-Shift-C
Navigate back                 Alt-Left          Alt-Y
Navigate forward              Alt-Right         Alt-Shift-Y
List tagged dirs              Alt-D

Search files
------------
Search by filename            Alt-F             Ctrl-F
... excl. dotfiles            Alt-Shift-F       Ctrl-T
Search by contents (regex)    Ctrl-G            'ggrep'

Other
-----
Autocomplete                  Tab
Autocomplete arguments        - & Tab
Find in autocomplete          Ctrl-F            Ctrl-S
Append '&| less'              Alt-P
Prepend 'sudo'                Alt-S
Manpage for current cmd       Alt-H             F1
What is word at cursor        Alt-W


========= Quick commands =========

Show this cheatsheet          cheat

Launch POSIX-compliant shell  oldshell

Change LC_NERDLEVEL           nerdlevel LEVEL
  0 No fish (launch bash)
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

Search files by content       ggrep REGEX
Search in file by content     ggrep-in-file FILE REGEX

(Re)open tmux / screen
  for user X                  $__multiplexer_names
  exclusive session 'one'     one
  steal session 'one'         forceone
  share session 'one'         shareone
  custom session              mmux SESSION [ ... see usage ]

Execute cmd in private,
... but allow edit            SPACE cmd
... and don't allow edit      SPACE SPACE cmd

Toggle full private mode      private

========== for admins ==========

List open network ports            lsports
List established connections       lsnet
dstat with saved preset            ddstat [ ... ]
SMART readout from /dev/NAME       ssmart NAME

mount /dev/NAME /run/q/NAME        qmount NAME
  ex. NAME for /dev/sda: sda
  ex. NAME for LVM: vg/lv
umount /run/q/NAME                 qumount NAME

mount --rbind /dev, /proc, /sys    qchroot [ TARGET ]
  into TARGET, then chroot,
  then umount on exit

	" | less
end

function __cheat_glyphs
	set -l pl_a1 (set_color 711)""(set_color -b 711)" "(set_color normal; set_color 711)""(set_color normal)
	set -l pl_a2 (set_color 171)""(set_color -b 171)" "(set_color normal; set_color 171)""(set_color normal)
	set -l pl_a3 (set_color yellow)""(set_color -b yellow)" "(set_color normal; set_color yellow)""(set_color normal)
	echo "For Nerdlevel 3, here's the Glyphs that your
terminal should display properly:

   ┌──────────────────────────┐
  │ Powerline Solid Arrow    └── This line is solid! (mc)
  │ Powerline Hollow Arrow
  │ Read-only lock
  │ Debian Swirl Logo
  │ Exit OK
  │ Exit Error            Powerlines: $pl_a1 $pl_a2 $pl_a3
  │ Hourglass End         Fine lines in-between? Try font size.
  │ Calendar
  │ Walking man
 ↓ │ Arrow Down (mc)
 ✕ │ Close X (mc)
───┘   
 __

The glyphs must not be cut off - some symbols appear as wide as these two
underscores! If they don't, your font is monospace and many icons are tiny.

And these fine colors should be distinguishable:
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
	echo
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
	echo
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
	echo
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
	echo
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
