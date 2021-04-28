function reinstall-shell-pack-prefs \
-d "Reinstalls mc, htop, tmux, screen preferences"
	echo "Overwrite preferences for"
	echo " - tmux"
	echo " - screen"
	echo " - htop"
	echo " - mc"
	read -n1 -P '? (Y/n) ' answer
	if [ "$answer" != "" ] && [ "$answer" != "y" ] && [ "$answer" != 'Y' ]
		echo "Skipping preferences."
		echo "run "(status "function")" any time if you change your mind"
		return
	end
	
	# files that are not easily edited by accident get linked
	# macos 'ln' does not have --relative, and it also misses realpath --relative-to
	# using absolute links for now. until we pull in coreutils anyways.
	rm -f ~/.tmux.conf
	ln -s "$__sp_config_dir/.tmux.conf" ~/.tmux.conf
	rm -f ~/.screenrc
	ln -s "$__sp_config_dir/.screenrc" ~/.screenrc
	
	# files that are easily edited by accident get copied
	mkdir -p ~/.config/htop
	rm -f ~/.config/htop/htoprc
	cp "$__sp_config_dir/htop/htoprc" ~/.config/htop/htoprc
	mkdir -p ~/.config/mc
	rm -f ~/.config/mc/ini
	cp "$__sp_config_dir/mc/ini" ~/.config/mc/ini
	rm -f ~/.config/mc/mc.keymap
	cp "$__sp_config_dir/mc/mc.keymap" ~/.config/mc/mc.keymap
	rm -f ~/.config/mc/panels.ini
	cp "$__sp_config_dir/mc/panels.ini" ~/.config/mc/panels.ini
	
end
