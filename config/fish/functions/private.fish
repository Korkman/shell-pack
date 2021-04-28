function private -d "Toggle private mode"
	if [ -z "$fish_private_mode" ]
		clear
		set_color -b "purple"
		set_color "white"
		if [ "$theme_nerd_fonts" = "yes" ]
			set symbol ' '\ufaf8' '
		else
			set symbol ' ! '
		end
		set -l msg "$symbol Entering private mode. No history will be written to disk!"
		echo -n "$msg"
		set -l right_budget (math $COLUMNS - (string length "$msg") - 1)
		echo -n (string repeat -n $right_budget " ")
		set_color normal
		echo
		set -g fish_private_mode yes
		if set -q fish_history
			set -g __shellpack_old_fish_history "$fish_history"
		end
		set -g fish_history ""
	else
		
		set -ge fish_private_mode
		if set -q __shellpack_old_fish_history
			set -g fish_history "$__shellpack_old_fish_history"
			set -ge __shellpack_old_fish_history
		else
			set -g fish_history "default"
		end
		
		clear
		policeline "Leaving private mode. Ctrl-C to abort exit ..."
		sleep 3
		exit
		
	end
end
