function fish_greeting -d "shell-pack says hello"
	set theme_greeting_add ""
	if [ "$theme_powerline_fonts" = "yes" ]
		set theme_greeting_add $theme_greeting_add " + "(set_color -b 070; set_color fff)" powerline "(set_color normal; set_color 070)""(set_color normal)
	end
	if [ "$theme_nerd_fonts" = "yes" ]
		set theme_greeting_add $theme_greeting_add " + nerdfont "(set_color 070)" "(set_color normal)""
	end
	# NOTE: the following is split to workaround a bug in Windows Terminal
	# causing the powerline arrow to show no background color for the space.
	echo -n "Welcome to FISH $FISH_VERSION"
	echo -ne " + shell-pack "(shell-pack-version) $theme_greeting_add "\n"
	
	if [ "$UPGRADE_SHELLPACK" != "no" ]
		# check dependencies once a day
		set -l thisdate (date +%Y%m%d)
		if test "$__sp_last_date_check_deps" != "$thisdate"
			shell-pack-check-upgrade
			shell-pack-check-deps
			set --universal __sp_last_date_check_deps "$thisdate"
		end
	end
end
