#! /bin/sh


# autorun installer on first startup
if [ "$AUTOSTART" = "yes" -a ! -e ~/.local/share/shell-pack/config ]; then
	if [ -z "$LC_NERDLEVEL " ]; then
		export LC_NERDLEVEL=3
	fi
	~/Downloads/get.sh
	bash -l
else
	export SHELL=$(which bash)
	bash -l
fi
