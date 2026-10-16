function __sp_td_subcommands -d \
	"List td-* subcommands, used for both completion and the td usage text"
	for fn in (functions -a)
		if string match -q 'td-*' -- $fn
			string replace -r '^td-' '' -- $fn
		end
	end
end

function td -d \
	"Test-drive functions for development"
	argparse --stop-nonopt 'h/help' -- $argv
	or return 2
	set -l verb $argv[1]
	if set -q _flag_help
		set verb help
	end

	set fname "td-$verb"
	if set -q _flag_help || ! functions -q "$fname"
		echo "Usage: td SUBCOMMAND [args...]"
		echo
		echo "Subcommands:"
		for subcommand in (__sp_td_subcommands | sort)
			# functions --details --verbose always emits 5 fields; the 5th is the description
			set -l desc (functions --details --verbose "td-$subcommand")[5]
			printf '  %-10s %s\n' "$subcommand" "$desc"
		end
		set -q _flag_help
		and return 0
		or return 1
	end >&2
	$fname $argv[2..-1]
end

function td-no-man -d \
	"Uninstall manpages with any available package manager"
	argparse 'h/help' -- $argv
	or return 2
	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td no-man"
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	if command -q apk
		apk del --purge man-pages mdocml mandoc man-db 2>/dev/null
	else if command -q zypper
		zypper --non-interactive remove man man-pages man-pages-posix 2>/dev/null
	else if command -q dnf
		dnf -y remove man-db man-pages 2>/dev/null
	else if command -q pacman
		pacman -Rns --noconfirm man-db man-pages 2>/dev/null
	else if command -q apt
		apt-get -y remove man-db manpages 2>/dev/null
	else
		echo "No supported package manager found" >&2
		return 1
	end
end

function td-ggit -d \
	"Create a Git test repository"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td ggit"
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	mkdir -p "$HOME/ggit-test"
	cd "$HOME/ggit-test"; or return 1
	git init -q
	git config --global user.email 'you@example.com'
	git config --global user.name 'Your Name'
	printf 'New file\n' > newfile.txt
end

function td-user -d \
	"Create and switch to the test-drive user"
	argparse 'h/help' 'sudo' 'pw=' 'rm' 'chsh' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td user [--sudo] [--pw PASSWORD]"
		echo "       td user --rm"
		echo
		echo "  --chsh         Change shell to fish."
		echo "  --sudo         Grant shpuser sudo access."
		echo "  --pw PASSWORD  Set the shpuser password. With --sudo, require it for sudo."
		echo "  --rm           Delete the shpuser test user, including its home directory."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	if set -q _flag_rm
		if id shpuser >/dev/null 2>&1
			rm -f /etc/sudoers.d/010_shpuser
			if command -q userdel
				userdel --remove shpuser
			else
				deluser --remove-home shpuser
			end
		end
		return 0
	end

	if ! id shpuser >/dev/null 2>&1
		set -l shpuser_home '/problematic home/shpuser'

		mkdir -p "$shpuser_home"
		set -lx SHELL (command -v bash || command -v zsh || command -v ksh || command -v sh)
		if type -q useradd
			useradd shpuser --home-dir "$shpuser_home"
		else
			# direct passwd manipulation because adduser is not standardized
			# shpuser:x:1000:1000::/problematic home/shpuser:/bin/sh
			echo "shpuser:x:1000:1000::$shpuser_home:$SHELL" >> /etc/passwd
			echo "shpuser:x:1000:" >> /etc/group
		end
		cp -a /etc/skel/. "$shpuser_home"
		if set -q _flag_pw
			echo "setting pw"
			printf 'shpuser:%s\n' "$_flag_pw" | chpasswd
		end
		if set -q _flag_sudo
			mkdir -p /etc/sudoers.d
			if set -q _flag_pw
				printf 'shpuser ALL=(ALL) ALL\n' > /etc/sudoers.d/010_shpuser
			else
				printf 'shpuser ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/010_shpuser
			end
		end
		if set -q _flag_chsh
			if ! string match (command -v fish) < /etc/shells
				echo "Adding fish to /etc/shells"
				printf '%s\n' (command -v fish) >> /etc/shells
			end
			command -q chsh && chsh shpuser -s (command -v fish)
			or begin
				echo "chsh failed / unavailable, editing /etc/passwd with sed"
				sed -i 's|^\(shpuser:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*\):.*|\1:'(command -v fish | string replace -a '/' '\/')'|' /etc/passwd
			end
		end
		cp -a /root/Downloads "$shpuser_home"
		cd ~shpuser/Downloads || return 1
		chown -R shpuser:shpuser "$shpuser_home"
		# run "downloaded" installer
		FORCE_PRE_DOWNLOADED=y su shpuser -c "./get.sh" > /dev/null
		
		if test -e /root/.local/bin
			mkdir -p "$shpuser_home/.local/bin"
			cp -a /root/.local/bin "$shpuser_home/.local/bin"
		end
		
		if [ -e ~/Downloads/dool.d ]
			cp -a ~/Downloads/dool.d ~shpuser/.local/share/shell-pack/bin/
		end
		
		# patch profile to launch with LC_NERDLEVEL=3 and correct locale
		if ! test -e ~shpuser/.profile || ! string match nerdlevel.sh < ~shpuser/.profile
			echo 'export LC_NERDLEVEL=3' >> ~shpuser/.profile
			echo "export LC_ALL=$LC_ALL" >> ~shpuser/.profile
			echo "export LANG=$LANG" >> ~shpuser/.profile
			echo '. "$HOME/.local/share/shell-pack/config/nerdlevel.sh"' >> ~shpuser/.profile
		end
		# .bashrc too, as it overrides .profile if present
		if test -e ~shpuser/.bashrc && ! string match nerdlevel.sh < ~shpuser/.bashrc
			echo 'export LC_NERDLEVEL=3' >> ~shpuser/.bashrc
			echo "export LC_ALL=$LC_ALL" >> ~shpuser/.bashrc
			echo "export LANG=$LANG" >> ~shpuser/.bashrc
			echo '. "$HOME/.local/share/shell-pack/config/nerdlevel.sh"' >> ~shpuser/.bashrc
		end
		
		chown -R shpuser:shpuser "$shpuser_home"
	end
	
	echo "Turning into user shpuser"
	# a note on su -l: on alpine, that drops /usr/local/bin from PATH, which is where we installed fzf, rg, etc.
	cd ~shpuser && su -l shpuser
	echo "Returning to root"
	cd ~
end

function td-version -d \
	"Checkout a specific version of shell-pack"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td version [TAG]"
		echo
		echo "  Reinstall shell-pack from the /repo checkout using get.sh's local"
		echo "  git detection. TAG defaults to 'worktree' (a snapshot of /repo's"
		echo "  current working tree, including uncommitted/untracked changes)."
		echo "  Any other TAG is checked out via git in a scratch copy."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	if ! test -e /repo/get.sh
		echo "/repo/get.sh not found, was the repo mounted read-only as /repo?" >&2
		return 1
	end

	set -e __sp_last_date_check_deps
	rm -rf $HOME/.local/share/shell-pack/src
	/repo/get.sh $argv
	exec fish
end

function td-override -d \
	"Override a shell-pack function in .config/fish/functions"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help || ! set -q argv[1]
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td override [FUNCTION]"
		echo
		echo "  Override and edit function FUNCTION."
		set -q _flag_help
		and return 0
		or return 1
	end >&2
	
	set fn $argv[1]
	
	mkdir -p "$HOME/.config/fish/functions"
	# copy over or create new function
	if test -e "$HOME/.local/share/shell-pack/config/fish/functions/$fn.fish"
		cp "$HOME/.local/share/shell-pack/config/fish/functions/$fn.fish" "$HOME/.config/fish/functions/$fn.fish"
	else
		echo "NOTE: $fn.fish does not exist, creating a new file"
	end
	# prepend user config to fish_function_path to allow overrides
	if ! string match -q "set -p fish_function_path*" < "$HOME/.config/fish/config.fish"
		echo 'set -p fish_function_path "$HOME/.config/fish/functions"' >> "$HOME/.config/fish/config.fish"
	end
	# start editor
	__sp_editor "$HOME/.config/fish/functions/$fn.fish"
end

function td-edit-live -d \
	"Symlink shell-pack's src dir to /repo for live editing from the host"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td edit-live"
		echo
		echo "  Replace \$HOME/.local/share/shell-pack/src with a symlink to /repo,"
		echo "  so edits made on the host (outside the container) take effect"
		echo "  immediately, without needing to rerun td version."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	if ! test -e /repo/get.sh
		echo "/repo/get.sh not found, was the repo mounted read-only as /repo?" >&2
		return 1
	end

	set -l srcdir "$HOME/.local/share/shell-pack/src"
	rm -rf "$srcdir"
	ln -s /repo "$srcdir"
	echo "Linked $srcdir -> /repo"
	set -e __sp_last_date_check_deps
	exec fish
end

function td-test-cfc -d \
	"Run a short automated test suite for cfc and cfd"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td test-cfc"
		echo
		echo "  Round-trips data through cfc and cfd in a temporary directory,"
		echo "  covering files, directories, stdin / stdout and '-' arguments."
		echo "  Returns the number of failed checks (max 125)."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	set -l tmp (__sp_mkuniq --dir --xdg-runtime td-test-cfc)
	or return 1
	pushd "$tmp"; or return 1
	set -g __td_test_failed 0
	set -g __td_test_total 0

	printf 'hello\n' > a.txt
	printf 'dashed\n' > ./-d.txt
	mkdir -p dir/sub
	printf 'inner\n' > dir/sub/i.txt

	# usage: __td_check DESCRIPTION EXPECTED ACTUAL
	function __td_check
		set -g __td_test_total (math $__td_test_total + 1)
		if test "$argv[2]" = "$argv[3]"
			echo "ok     $argv[1]"
		else
			set -g __td_test_failed (math $__td_test_failed + 1)
			echo "FAILED $argv[1]: expected '$argv[2]', got '$argv[3]'"
		end
	end

	set -l formats gz
	for fmt in zst xz bz2
		set -l bin $fmt
		test $fmt = bz2; and set bin bzip2
		command -q $bin; and set -a formats $fmt
	end

	# stdin to stdout, explicit and default format
	for fmt in $formats
		__td_check "stdin | cfc - $fmt - | cfd -" hello (printf 'hello\n' | cfc - $fmt - 2>/dev/null | cfd - 2>/dev/null)
		__td_check "file to stdout ($fmt)" hello (cfc a.txt $fmt 2>/dev/null | cfd - 2>/dev/null)
	end
	__td_check "stdin | cfc | cfd - (default format)" hello (printf 'hello\n' | cfc 2>/dev/null | cfd - 2>/dev/null)
	__td_check "stdin | cfc - - (explicit dashes)" hello (printf 'hello\n' | cfc - - 2>/dev/null | cfd - 2>/dev/null)

	# compressor args after --
	__td_check "compressor args pass through" hello (cfc a.txt gz -- -1 2>/dev/null | gzip -dc)
	cfc a.txt gz -- --bogus-option >/dev/null 2>&1
	__td_check "invalid compressor args fail" 1 $status

	# directories
	__td_check "directory to stdout as tar.gz" sub/i.txt (cfc dir tar.gz 2>/dev/null | tar tz | string match 'dir/sub/i.txt' | string replace 'dir/' '')
	mkdir out-dir
	cfc dir tar.gz > dir.tar.gz 2>/dev/null
	cfd dir.tar.gz out-dir >/dev/null 2>&1
	__td_check "cfd extracts directory archive" inner (cat out-dir/dir/sub/i.txt 2>/dev/null)

	# files named like options
	__td_check "file starting with a dash" dashed (cfc ./-d.txt gz 2>/dev/null | gzip -dc)
	__td_check "file starting with a dash, no ./" dashed (cfc -d.txt gz 2>/dev/null | gzip -dc)

	# cfd on files
	cfc a.txt gz > a.txt.gz 2>/dev/null
	__td_check "cfd FILE - (stdout)" hello (cfd a.txt.gz - 2>/dev/null)
	cfd a.txt.gz copy.txt >/dev/null 2>&1
	__td_check "cfd FILE DEST" hello (cat copy.txt 2>/dev/null)
	__td_check "cfd - FILE (stdin)" hello (cfd - < a.txt.gz 2>/dev/null)
	__td_check "cfd --get-type" gz (cfd --get-type a.txt.gz 2>/dev/null)

	# refusals
	printf 'x\n' | cfc - tar.gz - >/dev/null 2>&1
	__td_check "archive format from stdin is refused" 1 $status
	printf 'x\n' | cfc - gz extra - >/dev/null 2>&1
	__td_check "too many arguments with -" 1 $status

	# file destination with stdin (needs a terminal on stdout, emulated with script)
	if command -q script
		printf 'piped\n' | script -qec "fish -c 'cfc - from-stdin.gz'" /dev/null >/dev/null 2>&1
		__td_check "stdin to file destination" piped (gzip -dc from-stdin.gz 2>/dev/null)
	end

	popd
	rm -rf "$tmp"
	echo
	echo "$__td_test_total checks, $__td_test_failed failed"
	set -l failed $__td_test_failed
	set -e __td_test_failed __td_test_total
	functions -e __td_check
	test $failed -gt 125; and set failed 125
	return $failed
end

function td-test-comma -d \
	"Run a short automated test suite for the , (comma) function"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td test-comma"
		echo
		echo "  Checks binary integrity, lazy spawning, streaming, empty input"
		echo "  and exit status of ','. Returns the number of failed checks (max 125)."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	set -l tmp (__sp_mkuniq --dir --xdg-runtime td-test-comma)
	or return 1
	pushd "$tmp"; or return 1
	set -g __td_test_failed 0
	set -g __td_test_total 0

	# usage: __td_check DESCRIPTION EXPECTED ACTUAL
	function __td_check
		set -g __td_test_total (math $__td_test_total + 1)
		if test "$argv[2]" = "$argv[3]"
			echo "ok     $argv[1]"
		else
			set -g __td_test_failed (math $__td_test_failed + 1)
			echo "FAILED $argv[1]: expected '$argv[2]', got '$argv[3]'"
		end
	end

	# binary integrity, including a leading NUL and a leading newline
	head -c 1000000 /dev/urandom > rnd.bin
	cmp -s rnd.bin ( , cat < rnd.bin | psub ) 2>/dev/null
	__td_check "1 MB random data intact" 0 $status
	begin; printf '\0'; head -c 100000 /dev/urandom; end > nul.bin
	cmp -s nul.bin ( , cat < nul.bin | psub ) 2>/dev/null
	__td_check "leading NUL byte intact" 0 $status
	begin; printf '\n'; head -c 100000 /dev/urandom; end > nl.bin
	cmp -s nl.bin ( , cat < nl.bin | psub ) 2>/dev/null
	__td_check "leading newline intact" 0 $status
	printf '\377rest' | , cat > hi.bin
	__td_check "leading high byte intact" "ff 72 65 73 74" (od -An -v -tx1 < hi.bin | string trim | string replace -ra ' +' ' ')

	# arguments
	__td_check "command with arguments" ABC (echo abc | , string upper)
	__td_check "no command falls back to cat" noarg (echo noarg | ,)

	# empty input: no spawn, success
	printf '' | , touch spawned.marker
	__td_check "empty input returns 0" 0 $status
	__td_check "empty input does not spawn" no (test -e spawned.marker; and echo yes; or echo no)

	# exit status of the downstream command
	echo x | , sh -c 'cat >/dev/null; exit 7'
	__td_check "downstream exit status" 7 $status

	# spawn is delayed until the first byte arrives
	set -l start (date +%s)
	sh -c 'sleep 2; echo x' | , sh -c 'date +%s' | read -l spawn_at
	test (math $spawn_at - $start) -ge 2
	__td_check "spawn waits for data" 0 $status

	# output streams through while the producer is still running
	sh -c 'echo first; sleep 2; echo last' | , sh -c 'while read l; do echo "$l $(date +%s)"; done' | read -l first_line
	set -l first_at (string split ' ' -- $first_line)[2]
	set -l end_at (date +%s)
	test (math $end_at - $first_at) -ge 1
	__td_check "streams without buffering the input" 0 $status

	popd
	rm -rf "$tmp"
	echo
	echo "$__td_test_total checks, $__td_test_failed failed"
	set -l failed $__td_test_failed
	set -e __td_test_failed __td_test_total
	functions -e __td_check
	test $failed -gt 125; and set failed 125
	return $failed
end
