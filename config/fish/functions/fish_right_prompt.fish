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
	
	# bookkeeping
	if [ "$__display_cmd_stats" = "yes" ]
		# NOTE: assuming the fish_right_prompt is called last
		# reset cmd stats to prevent repeating them in invalid context
		set -g __display_cmd_stats "no"
	end
	
	# jobs segment
	if jobs -q
		set ijobs (__sp_get_pending_job_pids)
		set njobs (count $ijobs)
		echo -n ' '
		echo -n (__spt jobs_bg)(__spt left_black_arrow)
		__spt jobs_bg bg
		__spt jobs_fg
		if [ $njobs -lt 4 ]
			echo -n " "(__spt running) (string join -- ' ' $ijobs)
		else
			echo -n " "(__spt running)" x$njobs"
		end
	end
	
	# reload pending segment
	if [ "$__reload_pending" = "yes" ]
		echo -n (__spt warning_bg)(__spt left_black_arrow)
		echo -n (__spt warning_bg bg)(__spt warning_fg)" Update! Please 'reload' "
	else
		
		# user segment
		if fish_is_root_user
			set colorbg "user_root_bg"
			set colorfg "user_root_fg"
		else
			set colorbg "user_normal_bg"
			set colorfg "user_normal_fg"
		end
		
		echo -n " "(__spt $colorbg)(__spt left_black_arrow)
		echo -n (__spt $colorbg bg)(__spt $colorfg)" $USER@"$short_hostname" "
		
		# pid segment (only once)
		if set -q __right_prompt_pid_once
			echo -n (__spt pid_bg)(__spt left_black_arrow)
			echo -n (__spt pid_bg bg)(__spt pid_fg)" FISH pid $fish_pid "
			
			# shlvl segment (also only once)
			set -l offset_shlvl $SHLVL
			set -l offset_shlvl_visual ""
			if [ "$__term_muxer" != "none" ]
				set offset_shlvl (math $offset_shlvl - 1)
				set offset_shlvl_visual "+1"
			end
			if [ $offset_shlvl -gt 1 ]
				echo -n (__spt shlvl_bg)(__spt left_black_arrow)
				echo -n (__spt shlvl_bg bg)(__spt shlvl_fg)" Shlvl $offset_shlvl""$offset_shlvl_visual"" "
			end
		end
	end
	
	set_color normal
end

function __unpaint_right_prompt --on-event sp_submit_commandline -d \
	'Remove the right prompt as soon as enter is pressed to keep a 
	clean and resizable scrollback buffer'
	
	if set -q __right_prompt_pid_once
		# this is the only exception to keep it: for the stuff only displayed once
		set -eg __right_prompt_pid_once
		return
	end
	
	if ! set -q __skip_right_prompt_until_reset
		# right prompt is not hidden yet
		set -g __skip_right_prompt_until_reset yes
		if test (commandline | string collect) = ""
			# on empty commandline, paint blank line
			
			# move cursor to pos1
			echo -en '\r'
			# clear line
			#echo -en (string repeat -n $COLUMNS ' ')
			echo -en '\033[K'
			# move cursor to pos1
			echo -en '\r'
		else
			# on filled commandline, paint prompt without right prompt
			commandline -f repaint
		end
	else
		# right prompt is already hidden
		if test (commandline | string collect) = ""
			# on empty commandline, paint blank line
			
			# move cursor to pos1
			echo -en '\r'
			# clear line
			#echo -en (string repeat -n $COLUMNS ' ')
			echo -en '\033[K'
			# move cursor up
			#echo -en '\033[1A'
		end
		
	end
	
	# set (and reset) a timer to repaint the right prompt when resizing is complete
	__sp_set_timer "right_prompt_repaint" 1.5
end

function __unpaint_right_prompt_cancel --on-event sp_cancel_commandline -d \
	'Remove the right when ctrl-c is pressed to keep a 
	clean and resizable scrollback buffer'
	
	if set -q __right_prompt_pid_once
		# this is the only exception to keep it: for the stuff only displayed once
		set -eg __right_prompt_pid_once
		return
	end
	
	if ! set -q __skip_right_prompt_until_reset
		set -g __skip_right_prompt_until_reset yes
		commandline -f repaint
	end
	
	# set (and reset) a timer to repaint the right prompt when resizing is complete
	__sp_set_timer "right_prompt_repaint" 1.5
end

function __unpaint_right_prompt_winch --on-signal winch -d \
	'Remove the right prompt when the terminal is resized to keep a 
	clean and resizable scrollback buffer'
	
	if ! set -q __skip_right_prompt_until_reset
		set -g __skip_right_prompt_until_reset yes
		commandline -f repaint
	end
	
	# set (and reset) a timer to repaint the right prompt when resizing is complete
	__sp_set_timer "right_prompt_repaint" 1.5
end

function __sp_right_prompt_repaint --on-event "sp_timer_right_prompt_repaint"
	set -eg __skip_right_prompt_until_reset
	commandline -f repaint
end

function __clear_skip_right_prompt_until_reset --on-event fish_preexec -d \
	'Re-enable right prompt at preexec event'
	set -eg __skip_right_prompt_until_reset
	set -eg __right_prompt_pid_once
end

function disable-right-prompt -d \
	'Disable right prompt, for use in subshell'
	functions -e fish_right_prompt
	functions -e __unpaint_right_prompt
	functions -e __unpaint_right_prompt_cancel
	functions -e __unpaint_right_prompt_winch
	functions -e __clear_skip_right_prompt_until_reset
end

function enable-right-prompt -d \
	'Enable right prompt after disabled with -disable-right-prompt'
	source (status --current-filename)
end
