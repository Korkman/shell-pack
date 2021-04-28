#! /usr/bin/env bash

# autorun installer on first startup
if [ "$AUTOSTART" == "yes" ] && [ ! -e ~/.local/share/shell-pack/config ]; then
	~/.local/share/shell-pack/src/get.sh;
fi
