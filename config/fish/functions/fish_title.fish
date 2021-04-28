function __update_tab_title -v tabtitle
	if [ -n "$STY" -o -n "$TMUX" ] # We are in a screen / tmux session
		echo -ne "\ek""$tabtitle""\e\\\\"
	end
end

function fish_title
	if set -q __saved_status && [ "$__saved_status" != "" ] && [ $__saved_status -ne 0 ]
		set statusprefix "!"
	end

	set cmd_budget 15
	set spccmd ""
	if [ "$__session_tag" != "" ]
		set sessprefix "#$__session_tag"
		fish_prompt_shorten_string sessprefix 10
		set cmd_budget 10
		set spccmd " "
	end

	if [ "$MC_SID" != "" ]
		# do not set title when invoked as mc subshell
		if [ "$__session_tag" != "" ]
			# unless tagged
			echo "$statusprefix""$sessprefix""$spccmd""mc>""$short_hostname ($USER)"
		end
		return
	end

	set curcmd (status current-command)
	fish_prompt_shorten_string curcmd $cmd_budget
	if [ "$curcmd" = "fish" ]
		set curcmd ""
		set spccmd ""
	end
	echo "$statusprefix""$sessprefix""$spccmd""$curcmd"">""$short_hostname ($USER)"
	
	if [ "$sessprefix" != "" ]
		set -g tabtitle "$statusprefix""$sessprefix""$spccmd""$curcmd"
	else
		if [ "$curcmd" = "" ]
			set curcmd "fish"
		end
		set -g tabtitle "$statusprefix""$curcmd"
	end

end
