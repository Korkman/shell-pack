function cheat
	if [ "$argv[1]" = "--help" ]
		# --help always shows the shell-pack cheatsheet, bypassing any native 'cheat' command
		set argv[1] --shell-pack
	end

	if [ "$argv[1]" = "--glyphs" ]
		__sp_cheat_glyphs
		return
	end

	if [ "$argv[1]" = "--colors" ] || [ "$argv[1]" = "--colours" ]
		__sp_cheat_colors
		return
	end

	if string match -q -- "--color=*" "$argv[1]"
		__sp_cheat_color_value (string split -m1 "=" -- $argv[1])[2]
		return
	end

	if [ "$argv[1]" = "--mc" ]
		__sp_cheat_mc
		return
	end

	if [ "$argv[1]" = "--tmux" ]
		__sp_cheat_tmux
		return
	end

	if [ "$argv[1]" = "--fzf-query" ]
		__sp_cheat_fzf_query
		return
	end

	if [ "$argv[1]" = "--chtsh" ]
		set -e argv[1]
		set -l response
		if test -z "$argv[1]"
			dl --cache=7d --cache-allow-stale --silent https://cheat.sh 2>&1 | read -z response
		else
			dl --cache=7d --cache-allow-stale --silent https://cheat.sh/$argv[1] 2>&1 | read -z response
		end
		set -l exit_status $status
		if test $status -eq 0
			echo -- $response | __sp_pager -R
		else
			echo -- "Error connecting to cheat.sh"
			return $exit_status
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
Show color INDEX as RGB/hex   cheat --color=INDEX
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

Fetch man page from internet       onman [ --os DISTRO:VER ] [ SECTION ] PAGE
Download with curl or wget         dl URL [ FILENAME ]
Compressed file creation           cfc FILE|DIR [ FILE|ALGO ]
Compressed file decompression      cfd FILE [ DESTINATION ]
Copy to client clipboard           cclip FILE
SSH, but managed                   qssh [ ssh-params ]
git add + commit with review       ggit
Create and edit a template         create [ bash | fish | service | ... ] FILE
Encrypt a file                     qcrypt -e [--gpg] FILE OUTFILE
Decrypt a stream                   cat data | qcrypt -d [--gpg] | cat

	" | __sp_pager --prompt "cheat --shell-pack | less - q to quit, h for help"
end
