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
		# useradd will take $SHELL as a default, so make it a POSIX one
		set -lx SHELL (command -v bash || command -v zsh || command -v ksh || command -v sh)
		useradd shpuser --home-dir "$shpuser_home"
		cp -aT /etc/skel "$shpuser_home"
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

	rm -rf $HOME/.local/share/shell-pack/src
	/repo/get.sh $argv
	echo "maybe run:"
	echo shell-pack-check-deps
	echo reinstall-shell-pack-prefs
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
	echo "maybe run:"
	echo shell-pack-check-deps
	echo reinstall-shell-pack-prefs
end