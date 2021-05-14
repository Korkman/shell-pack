#! /bin/sh


# autorun installer on first startup
if [ "$AUTOSTART" = "yes" -a ! -e ~/.local/share/shell-pack/config ]; then
	if [ -z "$LC_NERDLEVEL " ]; then
		export LC_NERDLEVEL=3
	fi

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

	FORCE_PRE_DOWNLOADED=y ~/Downloads/get.sh

	FORCE_INSTALL_SP_PREFS=y bash -l

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
else
	export SHELL=$(which bash)
	bash -l
fi
