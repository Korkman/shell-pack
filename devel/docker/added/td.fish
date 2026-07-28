function td -d \
	"Test-drive functions for development"
	argparse --stop-nonopt 'h/help' -- $argv
	if test $status -ne 0
		return 2
	end

	set -l verb $argv[1]
	if set -q _flag_help
		set verb help
	end

	switch $verb
		case user
			td-user $argv[2..-1]
		case ggit
			td-ggit $argv[2..-1]
		case no-man
			td-no-man $argv[2..-1]
		case '*'
			printf 'Usage: td [user|ggit|no-man]\n' >&2
	end
end

function td-no-man -d \
	"Uninstall manpages with any available package manager"
	argparse 'h/help' -- $argv
	if test $status -ne 0
		return 2
	end

	if set -q _flag_help
		printf 'Usage: td no-man\n'
		return 0
	end

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
	if test $status -ne 0
		return 2
	end

	if set -q _flag_help
		printf 'Usage: td ggit\n'
		return 0
	end

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
	if test $status -ne 0
		return 2
	end

	if set -q _flag_help
		printf '%s\n' \
			'Usage: td user [--sudo] [--pw PASSWORD]' \
			'       td user --rm' \
			'' \
			'  --chsh         Change shell to fish.' \
			'  --sudo         Grant shpuser sudo access.' \
			'  --pw PASSWORD  Set the shpuser password. With --sudo, require it for sudo.' \
			'  --rm           Delete the shpuser test user, including its home directory.'
		return 0
	end

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