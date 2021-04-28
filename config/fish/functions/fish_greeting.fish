function fish_greeting -d "shell-pack says hello"
	set theme_greeting_add ""
	if [ "$theme_powerline_fonts" = "yes" ]
		set theme_greeting_add $theme_greeting_add " + "(set_color -b 070; set_color fff)" powerline "(set_color normal; set_color 070)""(set_color normal)
	end
	if [ "$theme_nerd_fonts" = "yes" ]
		set theme_greeting_add $theme_greeting_add " + nerdfont "(set_color 070)" "(set_color normal)""
	end
	echo -nes "Welcome to FISH $FISH_VERSION + shell-pack "(shell-pack-version) $theme_greeting_add "\n"
	
	# check dependencies once a day
	set -l thisdate (date +%Y%m%d)
	if test "$__sp_last_date_check_deps" != "$thisdate"
		shell-pack-check-deps
		set --universal __sp_last_date_check_deps "$thisdate"
	end
end
