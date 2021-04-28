function fish_right_prompt
	if [ "$MC_SID" != "" ]
		# make sure no right prompt is displayed when on mc subshell in stretch and jessie
		# NOTE: newer versions of mc erase fish_right_prompt, so we do it here as well
		functions -e fish_right_prompt
		return
	end

	if set -q __skip_right_prompt_until_reset
		return
	end

	if set -q __skip_right_prompt
		set -e __skip_right_prompt
		return
	end

	if [ "$MC_SID" != "" ]
		# make sure no right prompt is displayed when on mc subshell in stretch and jessie
		# NOTE: newer versions of mc erase fish_right_prompt, so we do it here as well
		functions -e fish_right_prompt
		return
	end

	__update_glyphs
	
	# bookkeeping
	if [ "$__display_cmd_stats" = "yes" ]
		# NOTE: assuming the fish_right_prompt is called last
		# reset cmd stats to prevent repeating them in invalid context
		set -g __display_cmd_stats "no"
	end
	
	# jobs segment
	if jobs -q
		set ijobs (jobs -g)
		set njobs (count $ijobs)
		echo -n ' '
		set_color bryellow
		echo -n $left_black_arrow_glyph
		set_color -b bryellow
		set_color black
		if [ $njobs -lt 4 ]
			echo -n " $running_glyph" (string join ' ' $ijobs)
		else
			echo -n " $running_glyph x$njobs"
		end
	end
	
	# reload pending segment
	if [ "$__reload_pending" = "yes" ]
		set colorbg "eee"
		set colorfg "f00"
		set_color $colorbg
		echo -n "$left_black_arrow_glyph"
		set_color -b $colorbg
		set_color $colorfg
		echo -n " Update! Please 'reload' "
	else
		
		# user segment
		# TODO: improve root user test
		if contains -- "$USER" root toor Administrator
			set colorbg "711"
			set colorfg "fff"
		else
			#set colorbg "0087af"
			#set colorfg "fff"
			set colorbg brblack
			set colorfg "fff"
		end
		set_color $colorbg
		echo -n " $left_black_arrow_glyph"
		set_color -b $colorbg
		set_color $colorfg
		echo -n " $USER@"$short_hostname" "
		
		# pid segment (only once)
		if set -q __right_prompt_pid_once
			set -e __right_prompt_pid_once
			set colorbg "070"
			set colorfg "fff"
			set_color $colorbg
			echo -n "$left_black_arrow_glyph"
			set_color -b $colorbg
			set_color $colorfg
			echo -n " FISH pid $fish_pid "
			
			# shlvl segment (also only once)
			set -l offset_shlvl $SHLVL
			set -l offset_shlvl_visual ""
			if [ "$__term_muxer" != "none" ]
				set offset_shlvl (math $offset_shlvl - 1)
				set offset_shlvl_visual "+1"
			end
			if [ $offset_shlvl -gt 1 ]
				set colorbg "3a3a3a"
				set colorfg "ff0"
				set_color $colorbg
				echo -n "$left_black_arrow_glyph"
				set_color -b $colorbg
				set_color $colorfg
				echo -n " Shlvl $offset_shlvl""$offset_shlvl_visual"" "
			end
		end
	end
	
	set_color normal
end

function __unpaint_right_prompt --on-signal winch --on-event "sp-submit-commandline" -d \
	'Remove the right prompt as soon as enter is pressed or the terminal is resized to keep a 
	clean and resizable scrollback buffer'
	if ! set -q __skip_right_prompt_until_reset
		set -g __skip_right_prompt_until_reset yes
		commandline -f repaint
	end
end

function __clear_skip_right_prompt_until_reset --on-event fish_preexec -d \
	'Re-enable right prompt at preexec event'
	set -e __skip_right_prompt_until_reset
end

function __clear_skip_right_prompt_until_reset_on_cancel --on-event fish_cancel -d \
	'Re-enable right prompt at cancel event'
	__clear_skip_right_prompt_until_reset
end

function disable-right-prompt
	functions -e fish_right_prompt
end

function enable-right-prompt
	source (status --current-filename)
end
