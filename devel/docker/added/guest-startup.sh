#! /bin/sh
{

# simulate pre-installed binaries
if [ -e ~/Downloads/rg ]
then
	cp ~/Downloads/rg /usr/local/bin/rg
fi
if [ -e ~/Downloads/fzf ]
then
	cp ~/Downloads/fzf /usr/local/bin/fzf
fi
if [ -e ~/Downloads/sk ]
then
	cp ~/Downloads/sk /usr/local/bin/sk
fi

onexit_copy_downloads() {
	# copy back downloaded files for later use
	if [ -e ~/.local/share/shell-pack/bin/rg ]
	then
		cp ~/.local/share/shell-pack/bin/rg ~/Downloads/rg
	fi
	if [ -e ~/.local/share/shell-pack/bin/fzf ]
	then
		cp ~/.local/share/shell-pack/bin/fzf ~/Downloads/fzf
	fi
	if [ -e ~/.local/share/shell-pack/bin/sk ]
	then
		cp ~/.local/share/shell-pack/bin/sk ~/Downloads/sk
	fi
	if [ -e ~/.local/share/shell-pack/bin/dool.d ] && [ ! -e ~/Downloads/dool.d ]
	then
		cp -a ~/.local/share/shell-pack/bin/dool.d ~/Downloads/
		# make world-writable so when Docker root created dool.d,
		#  host user 1000 is able to rm -rf $XDG_RUNTIME_DIR/shell-pack-test-drive-$tagname
		chmod ugo+rwX ~/Downloads/dool.d
		chmod ugo+rwX ~/Downloads/dool.d/plugins
	fi
}

trap onexit_copy_downloads exit term

if [ -z "$LC_NERDLEVEL" ]; then
	export LC_NERDLEVEL=3
fi
# setup an unprivileged user
useradd shpuser
mkdir -p /home/shpuser
cp -aT /etc/skel /home/shpuser
cp -a /root/Downloads /home/shpuser/
chown -R shpuser:shpuser /home/shpuser
echo "shpuser ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/010_shpuser"
chsh shpuser -s $(command -v fish) &> /dev/null || echo "chsh failed, might be unavailable in distro image. Please run 'fish'."

# autorun installer on first startup
if [ "$AUTOSTART" = "yes" -a ! -e ~/.local/share/shell-pack/config ]; then
	echo "-------------------------------------------------"
	echo "         Installer 'get.sh'             "
	echo "-------------------------------------------------"
	FORCE_PRE_DOWNLOADED=y ~/Downloads/get.sh
	cd ~shpuser/Downloads
	FORCE_PRE_DOWNLOADED=y su shpuser -c "./get.sh" > /dev/null
	cd ~
	if [ -e ~/Downloads/dool.d ]
	then
		echo "distributing dool.d ..."
		cp -a ~/Downloads/dool.d ~/.local/share/shell-pack/bin/
		cp -a ~/Downloads/dool.d ~shpuser/.local/share/shell-pack/bin/
	else
		echo "dool.d not cached!"
	fi
	
	echo "-------------------------------------------------"
	echo " Startup experience:                             "
	echo " - unprivileged user 'shpuser' created           "
	echo " - executing bash for 'root' with LC_NERDLEVEL=3 "
	echo "-------------------------------------------------"
	bash -l
else
	cd ~
	echo "-------------------------------------------------"
	echo " Autostart skipped:                     "
	echo " - unprivileged user 'shpuser' created  "
	echo " - get.sh is available in ~/Downloads   "
	echo " - executing bash with LC_NERDLEVEL=3   "
	echo "-------------------------------------------------"
	bash -l
fi

exit
}