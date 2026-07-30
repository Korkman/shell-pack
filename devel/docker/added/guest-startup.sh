#! /bin/sh
{

command -v fish > /dev/null || {
	echo "Fish not in PATH, installer failed!"
	cat "$HOME/fish_installer.log"
	bash -l
	exit
}

# simulate pre-installed binaries
if [ -e ~/Downloads/rg ]
then
	mv ~/Downloads/rg /usr/local/bin/rg
fi
if [ -e ~/Downloads/fzf ]
then
	mv ~/Downloads/fzf /usr/local/bin/fzf
fi

onexit_copy_downloads() {
	# copy back downloaded files for later use
	CACHED_FILES="rg fzf dool.d"
	for cached_file in $CACHED_FILES
	do
		if [ -e ~/.local/share/shell-pack/bin/$cached_file ]
		then
			if [ ! -e ~/Downloads/$cached_file ] || [ ~/.local/share/shell-pack/bin/$cached_file -nt ~/Downloads/$cached_file ]
			then
				cp -a ~/.local/share/shell-pack/bin/$cached_file ~/Downloads/
				# make world-writable so when Docker root created dool.d,
				#  host user 1000 is able to rm -rf $XDG_RUNTIME_DIR/shell-pack-test-drive-$tagname
				chmod ugo+rwX -R ~/Downloads/$cached_file
			fi
		fi
	
	done
}

trap onexit_copy_downloads EXIT TERM

if [ "$SHELL" = "" ]
then
	SHELL=$(command -v bash || command -v zsh || command -v ksh || command -v sh)
fi

# autorun installer
if [ "$AUTOSTART" = "yes" ]; then
	echo "------------------------------------------------------------"
	echo "                      Installer 'get.sh'                    "
	echo "------------------------------------------------------------"
	cd ~/Downloads || return 1
	FORCE_PRE_DOWNLOADED=y KEEP_DOWNLOAD=y ~/Downloads/get.sh
	cd ~ || return 1
	if [ -e ~/Downloads/dool.d ]
	then
		echo "distributing dool.d ..."
		cp -a ~/Downloads/dool.d ~/.local/share/shell-pack/bin/
	else
		echo "dool.d not cached!"
	fi
	
	# for distros that have no .profile in skel
	echo 'PAGER=ppage' >> ~/.profile
	echo '. "$HOME/.local/share/shell-pack/config/nerdlevel.sh"' >> ~/.profile
	
	echo "------------------------------------------------------------"
	echo " Environment:                                               "
	echo " - shell-pack setup is done                                 "
	echo " - executing login shell for 'root' with LC_NERDLEVEL=3     "
	echo " - run 'td user' for a non-root account                     "
	echo "------------------------------------------------------------"
	$SHELL -l
else
	cd ~ || return 1
	echo "------------------------------------------------------------"
	echo " Environment:                                               "
	echo " - shell-pack setup was skipped                             "
	echo " - get.sh is available in ~/Downloads                       "
	echo " - executing login shell for 'root' with LC_NERDLEVEL=3     "
	echo " - run 'td user' for a non-root account                     "
	echo "------------------------------------------------------------"
	$SHELL -l
fi

exit
}