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
	#echo "Checking if rg, sk were installed ..."
	# copy back downloaded files for later use
	if [ -e ~/.local/share/shell-pack/bin/rg ]
	then
		#echo "Caching rg ..."
		cp ~/.local/share/shell-pack/bin/rg ~/Downloads/rg
	fi
	if [ -e ~/.local/share/shell-pack/bin/fzf ]
	then
		#echo "Caching fzf .."
		cp ~/.local/share/shell-pack/bin/fzf ~/Downloads/fzf
	fi
	if [ -e ~/.local/share/shell-pack/bin/sk ]
	then
		#echo "Caching sk .."
		cp ~/.local/share/shell-pack/bin/sk ~/Downloads/sk
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
chsh shpuser -s $(command -v fish)

# autorun installer on first startup
if [ "$AUTOSTART" = "yes" -a ! -e ~/.local/share/shell-pack/config ]; then
	FORCE_PRE_DOWNLOADED=y ~/Downloads/get.sh
	cd ~shpuser/Downloads
	FORCE_PRE_DOWNLOADED=y su shpuser -c "./get.sh" > /dev/null
	cd ~
	FORCE_INSTALL_SP_PREFS=y bash -l
else
	cd ~
	bash -l
fi

exit
}