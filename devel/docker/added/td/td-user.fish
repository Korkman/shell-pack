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
