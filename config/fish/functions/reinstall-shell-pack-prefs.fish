__polyfill_cmp

function reinstall-shell-pack-prefs \
-d "Reinstalls mc, htop, tmux, screen preferences"
	
	set htop_config "htoprc"
	set htop_version "no version"
	if command -qv htop
		if string match -qr "htop (?<htop_version>[0-9]+\.[0-9]+\.[0-9]+)" -- (htop --version)
			if test (__sp_vercmp "$htop_version" "3.2.2") -ge 0
				set htop_config "htoprc.322"
			else if test (__sp_vercmp "$htop_version" "3.0.5") -ge 0
				set htop_config "htoprc.305"
			end
		end
	end
	
	if  cmp --silent -- "$__sp_config_dir/.tmux.conf" ~/.tmux.conf
	and cmp --silent -- "$__sp_config_dir/.screenrc" ~/.screenrc
	and cmp --silent -- "$__sp_config_dir/htop/$htop_config" ~/.config/htop/htoprc
	and cmp --silent -- "$__sp_config_dir/mc/ini" ~/.config/mc/ini
	and cmp --silent -- "$__sp_config_dir/mc/mc.keymap" ~/.config/mc/mc.keymap
	and cmp --silent -- "$__sp_config_dir/mc/panels.ini" ~/.config/mc/panels.ini
		echo "Your preferences are up-to-date"
		return
	end
	
	echo "Your preferences do not match recommendations. Overwrite:"
	echo " - tmux / screen"
	echo " - htop"
	echo " - mc"
	if [ "$FORCE_INSTALL_SP_PREFS" = "y" ]
		set answer y
		set -ge FORCE_INSTALL_SP_PREFS
	else
		read -P '? (Y/n) ' answer || set answer n
	end
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
	cp "$__sp_config_dir/htop/$htop_config" ~/.config/htop/htoprc
	mkdir -p ~/.config/mc
	rm -f ~/.config/mc/ini
	cp "$__sp_config_dir/mc/ini" ~/.config/mc/ini
	rm -f ~/.config/mc/mc.keymap
	cp "$__sp_config_dir/mc/mc.keymap" ~/.config/mc/mc.keymap
	rm -f ~/.config/mc/panels.ini
	cp "$__sp_config_dir/mc/panels.ini" ~/.config/mc/panels.ini
	
end
