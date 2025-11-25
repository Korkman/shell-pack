function fish_prompt -d \
	"shell-pack prompt"
	if [ (status function) = "fish_prompt_mc" ]
		# this function was copied and renamed by mc to fish_prompt_mc
		
		# it is likely mc spammed the history, so we erase it immediately
		# (Debian Jessie and Stretch affected, fixed in Buster)
		if ! set -q __mc_history_cleared
			set -g __mc_history_cleared yes
			echo "all" | history delete --prefix "if not functions -q fish_prompt_mc;" &> /dev/null
		end
		
		# some hotfixing for the mc prompt
		if ! set -q mc_prompt_fixed
			# fish 3.3.0 started sending \r in capable terminals, which mc does not expect.
			# setting TERM to "dumb" and reverting at tactical places is a wonky workaround I can apply here.
			# fish 3.6.1 added a better workaround on their own, because mc devs haven't incorporated the bugfix yet
			set -l play_dumb
			if test (__sp_vercmp "$FISH_VERSION" '3.3.0') -ge 0 -a (__sp_vercmp "$FISH_VERSION" '3.6.1') -lt 0
				set play_dumb yes
			else
				set play_dumb no
			end
			
			set -g mc_prompt_fixed yes
			set -g mc_true_term "$TERM"
			
			set -l mc_prompt (functions fish_prompt)
			# # Defined interactively
			# function fish_prompt
			# echo "$PWD">&7; fish_prompt_mc; kill -STOP %self;
			# end
			
			# ^ this is how we expect fish_prompt to look like when overwritten by mc
			# note that >&7 is a variable pipe number

			set -l filtered_mc_prompt
			for mc_line in $mc_prompt
				if string trim -- "$mc_line" | string match -q "#*"
					# comment lines must be filtered or eval will not work!
					continue
				end
				
				# terrible bug in Debian Stretch: an additional prompt line!
				# let's remove it
				set mc_line (string replace --regex 'echo \(whoami\)[^;]+;' '' -- "$mc_line")
				
				if [ "$play_dumb" = "yes" ]
					# append 'set -g TERM dumb' after 'kill .*;'
					set mc_line (string replace --regex 'kill .*;' '$0 set -g TERM dumb' -- "$mc_line")
					
					# prepend 'set -g TERM $mc_true_term' before 'echo $PWD'
					set mc_line (string replace --regex 'echo "\$PWD' 'set -g TERM "$$mc_true_term"; $0' -- "$mc_line")
				end
				
				# save to list of lines
				set -a filtered_mc_prompt "$mc_line;"
			end
			
			# redefine fish_prompt
			eval "$filtered_mc_prompt"
			
			if [ "$play_dumb" = "yes" ]
				# also hook preexec to swap TERM for saved value
				function term_not_dumb_on_exec --on-event fish_preexec -d \
					"Revert to saved TERM value pre-exec"
					set -g TERM "$mc_true_term"
				end

				# set TERM dumb NOW to have first prompt working on iTerm2
				set -g TERM dumb
			end
		end
	end
	
	if set -q __skip_prompt
		set -e __skip_prompt
		return
	end
	
	fish_prompt_reset_segments
	set -l pwd_budget 40
	if ! functions -q fish_right_prompt
		# left-hand versions of right prompt segments
		
		# backgrounded jobs
		if jobs -q
			set -l ijobs (__sp_get_pending_job_pids)
			set -l njobs (count $ijobs)
			if [ $njobs -lt 4 ]
				fish_prompt_segment "jobs_bg" "jobs_fg" (__spt running)" "(string join -- ' ' $ijobs)
			else
				fish_prompt_segment "jobs_bg" "jobs_fg" (__spt running)" x$njobs"
			end
		end
		
		# reload pending segment
		if [ "$__reload_pending" = "yes" ]
			fish_prompt_segment "warning_bg" "warning_fg" "New FISH! Reload!"
		end
	end
	
	if [ "$debian_chroot" != "" ]
		# autotag with $debian_chroot
		set -l chroot_tag "($debian_chroot)"
		fish_prompt_shorten_string chroot_tag 12
		__fish_prompt_reduce_pwd_budget chroot_tag
		fish_prompt_segment "chroot_bg" "chroot_fg" "$chroot_tag"
	end

	# python virtual_env support
	if set -q VIRTUAL_ENV
		# shorten VIRTUAL_ENV once
		# strip hidden directory name (typically .venv) at end of path
		# basename of remaining path = tag name
		if ! set -q _SP_VENV_TAG
			set -gx _SP_VENV_TAG (basename (string replace --regex -- "/\.[^/]+\$" "" "$VIRTUAL_ENV"))
		end
		fish_prompt_shorten_string _SP_VENV_TAG 20
		set -l venv_prefix "venv:"
		__fish_prompt_reduce_pwd_budget _SP_VENV_TAG
		__fish_prompt_reduce_pwd_budget venv_prefix
		fish_prompt_segment "venv_bg" "venv_fg" "$venv_prefix""$_SP_VENV_TAG"
	else
		if set -q _SP_VENV_TAG
			set -g -e _SP_VENV_TAG
		end
	end
	
	if [ "$__session_tag" != "" ]
		set -l visual_session_tag "$__session_tag"
		fish_prompt_shorten_string visual_session_tag 20
		# subtract taken space from pwd budget
		__fish_prompt_reduce_pwd_budget visual_session_tag
		fish_prompt_segment "tag_bg" "tag_fg" (__spt tag)"$visual_session_tag"
	else
	end
	
	if [ ! -z "$fish_private_mode" ]
		fish_prompt_segment "confidential_bg" "confidential_fg" (__spt confidential)
	end
	
	if set -q __sp_fiddle_mode
		# show fiddling mode
		fish_prompt_segment "fiddle_bg" "fiddle_fg" (__spt fiddle)" "
	else
		__sp_prompt_add_path_segments
	end
	
	fish_prompt_print_segments
end

function __sp_prompt_add_path_segments --no-scope-shadowing
	if [ "$PWD" = "/" ]
		# special case root-dir
		fish_prompt_segment "pwd_bg" "pwd_fg" "/"
	else
		# find longest matching tagged dir
		set matched_len_tagged_dir_path 0
		set -ge matched_tagged_dir_name
		for tagged_dir in $__tagged_dirs
			set tagged_dir_path "$__tagged_dirs_path_list[$tagged_dir]"
			set tagged_dir_name "$__tagged_dirs_name_list[$tagged_dir]"
			set len_tagged_dir_path (string length -- "$tagged_dir_path")
			if [ $len_tagged_dir_path -gt $matched_len_tagged_dir_path -a (string sub --start 1 --length (math $len_tagged_dir_path + 1) -- "$PWD/") = "$tagged_dir_path/" ]
				set matched_len_tagged_dir_path $len_tagged_dir_path
				set matched_tagged_dir_path "$tagged_dir_path"
				set -g matched_tagged_dir_name "$tagged_dir_name"
			end
		end
		
		set len_home (string length -- "$HOME")
		if [ "$matched_tagged_dir_path" != "" ]
			set visual_pwd (string sub --start (math $matched_len_tagged_dir_path + 1) -- "$PWD")
			if [ "$_SP_VENV_TAG" = "$matched_tagged_dir_name" ]
				# shortcut: if virtual environment matches directory tag, skip the directory tag
			else
				fish_prompt_segment "bookmark_bg" "bookmark_fg" (__spt bookmark)"$matched_tagged_dir_name"
			end
		else if [ $len_home -gt 0 -a (string sub --start 1 --length $len_home -- "$PWD") = "$HOME" ]
			# home indicator
			# prefix replace ~
			set visual_pwd (string sub --start (math $len_home + 1) -- "$PWD")
			fish_prompt_segment "bookmark_bg" "bookmark_fg" (__spt home)
		else
			set visual_pwd "$PWD"
		end
		
		if [ "$visual_pwd" != "" ]
			fish_prompt_shorten_path visual_pwd $pwd_budget
			if [ "$theme_powerline_fonts" = "no" ]
				# simply leave slashes as-is with no powerline fonts
				fish_prompt_segment "pwd_bg" "pwd_fg" "$visual_pwd"
			else
				# split into segments
				set visual_pwd (string trim --left --chars '/' -- "$visual_pwd")
				set path_segments (string split '/' -- $visual_pwd)
				set cnt_path_segments (count $path_segments)
				set idx_path_segments 0
				for path_segment in $path_segments
					set idx_path_segments (math $idx_path_segments + 1)
					if [ $idx_path_segments -eq $cnt_path_segments ]
						set segment_color "pwd_fg"
					else
						set segment_color "pwd_fg_dim"
					end
					fish_prompt_segment "pwd_bg" "$segment_color" "$path_segment" "pwd_fg_dim_sep"
				end
			end
		end
	end
	
	# lock-icon for write-protected
	if [ ! -w "$PWD" ]
		fish_prompt_segment "readonly_bg" "readonly_fg" (__spt lock)
	end
	
end

function fish_prompt_shorten_path --no-scope-shadowing -d "Shorten path to percentage of COLUMNS: string percentage"
	set --local vname $argv[1]
	set --local p $argv[2]
	set --local max (math $COLUMNS / 100 x $p)
	if [ (string length -- "$$vname") -gt $max ]
		set --local llen (math round\($max / 2 - 0.5\))
		set --local rlen (math round\($max / 2 + 0.5\))
		if [ $llen -lt 0 ]
			set llen 0
		end
		if [ $rlen -lt 0 ]
			set rlen 0
		end
		set --local lpart (string sub --start 1 --length $llen -- "$$vname" )
		set --local rpart (string sub --start -$rlen -- "$$vname")
		set lpart (string replace --regex '[^/]+$' "" -- "$lpart")
		set rpart (string replace --regex '^[^/]+' "" -- "$rpart")
		set $vname "$lpart""…""$rpart"
	end
end

function __fish_prompt_reduce_pwd_budget --no-scope-shadowing -d "Reduce the percentual pwd_budget by an absolute string length"
	set pwd_budget (math $pwd_budget - (math 100 / $COLUMNS x (string length -- "$$argv[1]")))
end

function fish_prompt_reset_segments --no-scope-shadowing -d "Reset segments to null"
	set __fish_prompt_segments_bgcolor_list
	set __fish_prompt_segments_fgcolor_list
	set __fish_prompt_segments_content_list
	set __fish_prompt_segments_dim_fgcolor_list
	set __fish_prompt_segments
end

function fish_prompt_segment --no-scope-shadowing -d "Add a segment to be printed: bgcolor fgcolor content [dim_fgcolor]"
	# start count at 1
	set __fish_prompt_segments $__fish_prompt_segments (count x $__fish_prompt_segments)
	
	set __fish_prompt_segments_bgcolor_list $__fish_prompt_segments_bgcolor_list $argv[1]
	set __fish_prompt_segments_fgcolor_list $__fish_prompt_segments_fgcolor_list $argv[2]
	set __fish_prompt_segments_content_list $__fish_prompt_segments_content_list $argv[3]
	set --local dim_fgcolor "$argv[2]"
	if [ "$argv[4]" != "" ]
		set dim_fgcolor "$argv[4]"
	end
	set __fish_prompt_segments_dim_fgcolor_list $__fish_prompt_segments_dim_fgcolor_list $dim_fgcolor
end

function fish_prompt_print_segments --no-scope-shadowing
	# condensed style
	set --local space
	if [ "$COLUMNS" -lt 80 ]
		set space ""
	else
		set space " "
	end
	
	set --local prev_bgcolor
	for segment in $__fish_prompt_segments
		set --local bgcolor $__fish_prompt_segments_bgcolor_list[$segment]
		set --local fgcolor $__fish_prompt_segments_fgcolor_list[$segment]
		set --local dim_fgcolor $__fish_prompt_segments_dim_fgcolor_list[$segment]
		__spt $bgcolor bg
		if [ $segment -gt 1 ]
			if [ "$bgcolor" = "$prev_bgcolor" ]
				echo -n (__spt $dim_fgcolor)(__spt right_arrow)
			else
				echo -n (__spt $prev_bgcolor)(__spt right_black_arrow)
			end
		end
		__spt $fgcolor
		echo -n -- "$space""$__fish_prompt_segments_content_list[$segment]""$space"
		
		set prev_bgcolor $bgcolor
	end
	set_color normal
	
	echo -n (__spt $prev_bgcolor)(__spt right_black_arrow)
	set_color normal
	echo -n "$space"
end

function __shellpack_get_string_term_lines -d "Return count of terminal lines a string approx. uses to display with current prompt"
	set -l linesburned 0
	
	# calculate approx. promptlength (some ultra-wide / invisible utf-8 chars will mess this up)
	set -l promptlength (fish_prompt | string replace -ra '\e\[[^m]*m' '' | string length)
	
	# walk all actual lines in input
	while read -l line
		set -l this_line_length (string length -- "$line")
		set linesburned (math "$linesburned + ceil(($this_line_length + $promptlength - 1) / $COLUMNS)")
	end
	
	echo $linesburned
end

function __shellpack_erase_command_lines -d "Try to erase all lines a typed cmd took to display, assuming cursor is at the end"
		__shellpack_get_string_term_lines | read linesburned
		#set -l linesburned 2
		for i in (seq 0 $linesburned)
			# move cursor up
			echo -en '\033[1A'
			# clear line
			echo -en '\033[2K'
		end
end

function __shellpack_confidential -e fish_preexec -d "Mask confidential cmd from output"
	if set -q MC_SID
		# output from within mc subshell breaks navigation
		return
	end
	
	set -l __new_cmdline (echo "$argv[1]")
	set -g __shellpack_current_cmd_user_hidden no
	set -g __shellpack_current_cmd_confidential no
	if [ (string length -- "$__new_cmdline") -gt 2 ] && string match -- "  " (string sub -s 1 -l 2 -- "$__new_cmdline") ]
		# two spaces: internal code for "hidden from user"
		echo "$argv[1]" | __shellpack_erase_command_lines
		set -g __shellpack_current_cmd_user_hidden yes
	else if [ (string length -- "$__new_cmdline") -gt 1 ] && string match -- " " (string sub -s 1 -l 1 -- "$__new_cmdline") ]
		echo "$argv[1]" | __shellpack_erase_command_lines
		# reminder to clear history
		fish_prompt_reset_segments
		fish_prompt_segment "confidential_bg" "confidential_fg" (__spt confidential)
		fish_prompt_print_segments
		echo "Private history: 'up' to edit. Solo space or other cmd clears."
		set -g __shellpack_current_cmd_confidential yes
	end
end

function enhanced_prompt -e fish_postexec -d "Foreground and background job execution tracking and status code clearance"
	set -g __saved_pipestatus (string split ' ' -- "$pipestatus")
	# NOTE: $status is gone at this point
	set -g __saved_status $__saved_pipestatus[(count $__saved_pipestatus)]
	set -g __saved_duration "$CMD_DURATION"
	set -x __job_start_time (__sp_getnanoseconds)
	set -g __saved_cmdline (echo "$argv[1]" | begin set -l d ''; while read line; echo -n "$d""$line"; set d '; '; end; end)
	
	# detect tracked, but lost jobs (e.g. by kill)
	if [ "$__watched_job_pids" != "" ]
		for job_pid in $__watched_job_pids
			if ! ps -p $job_pid &> /dev/null
				job_watcher$job_pid "KILLED?" 0 -2
			end
		end
	end
	
	# detect new untracked jobs
	if jobs -q
		#set new_bg_tasks ""
		for job_pid in (__sp_get_pending_job_pids)
			# NOTE: multiple pids may be spawned within one job
			# we take the naive approach to watch the last pid returned by jobs -p %x
			# , hoping it will be the last command in pipe.
			if ! functions -q job_watcher$job_pid
				# untracked backgrounded task detected
				set -g __watched_job_pids $__watched_job_pids $job_pid
				set new_bg_tasks $job_pid $new_bg_tasks
				function job_watcher$job_pid -V job_pid -V __job_start_time -V __saved_cmdline --on-process-exit "$job_pid"
					# remove my pid from list
					set -ge __watched_job_pids[(contains -i $job_pid $__watched_job_pids)]

					set job_status $argv[3]
					set duration (math "round(("(__sp_getnanoseconds)" - $__job_start_time ) / 1000 / 1000)")

					echo
					__spt jobs_bg bg
					__spt jobs_fg
					if [ (string length -- "$__saved_cmdline") -gt 20 ]
						echo -n ' '(string sub -l 9 -- "$__saved_cmdline")'…'(string sub -s -9 -- "$__saved_cmdline")' '
					else
						echo -n " "$__saved_cmdline" "
					end
					set_color normal
					__spt jobs_bg
					echo -n (__spt right_black_arrow)" "
					if [ $job_status -eq 0 ]
						__spt status_ok
						echo -n (__spt happy)" "
					else
						__spt status_fail
						echo -n (__spt unhappy)" $job_status "
					end
					set_color $fish_color_autosuggestion
					echo -n "$argv[1] "
					echo -n "$job_pid "
					__shellpack_cmd_duration $duration
					__shellpack_timestamp
					set_color normal
					commandline -f repaint
					functions --erase job_watcher$job_pid
				end
			end
		end
		
		if [ (count $new_bg_tasks) -gt 0 ]
			# tracking new background tasks
			if [ (count $new_bg_tasks) -gt 1 ]
				set plural PIDs
			else
				set plural PID
			end
			__spt jobs_bg bg
			__spt jobs_fg
			echo -n " "(__spt running)" "
			set_color normal
			__spt jobs_bg
			echo -n (__spt right_black_arrow)
			set_color normal
			echo " New job $plural $new_bg_tasks"
		end
	end

	set -l do_show_exit_status "yes"
	if set -q status_generation
		# status_generation exists since fish 3.2, use it
		if test "$status_generation" = "$__sp_last_status_generation"
			set do_show_exit_status "no"
		else
			set -g __sp_last_status_generation $status_generation
		end
	else if [ "$__saved_cmdline" = "" ] || [ (string trim -- (string sub -s -1 -l 1 -- "$__saved_cmdline")) = "&" ]
		# empty line submitted or ends in "&"
		set do_show_exit_status "no"
	end

	if [ "$__shellpack_current_cmd_user_hidden" = "yes" ]
		# user hidden, no status line
		set do_show_exit_status "no"
	end

	# ignore empty lines and backgrounding tasks
	if [ "$do_show_exit_status" = "yes" ]
		set -g __display_cmd_stats yes

		# output cmd
		if [ $__saved_status -eq 0 ]
			set thisbg (__spt cmd_ok_bg bg)
			set thisfg (__spt cmd_ok_fg)
			set thisfg_inv (__spt cmd_ok_bg)
		else
			set thisbg (__spt cmd_fail_bg bg)
			set thisfg (__spt cmd_fail_fg)
			set thisfg_inv (__spt cmd_fail_bg)
		end
		echo -n "$thisbg"$thisfg
		if [ "$__shellpack_current_cmd_confidential" = "yes" ]
			echo -n ' '(__spt confidential)' '
		else
			if [ (string length -- "$__saved_cmdline") -gt 40 ]
				echo -n ' '(string sub -l 19 -- "$__saved_cmdline")'…'(string sub -s -19 -- "$__saved_cmdline")' '
			else
				echo -n " "$__saved_cmdline" "
			end
		end
		set_color -b normal
		echo -n "$thisfg_inv"(__spt right_black_arrow)" "

		if [ $__saved_status -eq 0 ]
			echo -n (__spt status_ok)(__spt happy)" "
		else
			__spt status_fail
			# ring the bell
			echo -n \a
			echo -n (__spt unhappy)" ""$__saved_status "
		end
		set_color $fish_color_autosuggestion
		__shellpack_cmd_duration
		__shellpack_timestamp
		set_color normal
		
		# hot new info: $pipestatus if any -ne 0
		if [ (count $__saved_pipestatus) -gt 1 ]
			set total_pipestatus 0
			for substatus in $__saved_pipestatus
				if [ $substatus -gt 0 ]
					set total_pipestatus "$substatus"
				end
			end
			if [ $total_pipestatus -gt 0 ]
				echo -n (__spt cmd_fail_bg bg)(__spt cmd_fail_fg)" Non-zero exit status in pipe "
				set_color -b normal
				echo -n (__spt cmd_fail_bg)(__spt right_black_arrow)" "
				set forcount 0
				for substatus in $__saved_pipestatus
					set forcount (math $forcount + 1)

					if [ $substatus -gt 0 ]
						__spt status_fail
					else
						__spt status_ok
					end
					echo -n "$substatus "
					if [ $forcount -lt (count $__saved_pipestatus) ]
						set_color $fish_color_autosuggestion
						echo -ne (__spt right_arrow)" "
					end
				end
				set_color normal
				echo
			end
		end
		
	else
		# empty line submitted, want a spacer
		# NOTE: empty echo disturbs tmux, therefore a space
		echo " "
	end
	
	# NOTE: detecting nerdlevel downgrade to zero is possible here
	#       but potentially unwanted.
	#if [ "$LC_NERDLEVEL" = "0" ]
	#	nerdlevel 0
	#end
	
	# if not already pending, detect if config.fish has to be reloaded
	if [ "$__reload_pending" != "yes" ]
		if [ "$__sp_config_fish_file" = "" ] \
			|| [ "$__sp_config_fish_md5" = "" ] \
			|| [ (__sp_getmtime $__sp_config_fish_file) -ne $__sp_config_fish_mtime ]

			set -l new_md5 "invalid"
			if functions -q __sp_getmd5
				set new_md5 (__sp_getmd5 $__sp_config_fish_file)
			end

			if [ "$new_md5" = "$__sp_config_fish_md5" ]
				# unchanged md5 - update timestamp, no reload necessary
				#echo "config.fish changed mtime, but md5 is equal, no action required"
				set -g __sp_config_fish_mtime (__sp_getmtime $__sp_config_fish_file)
			else
				# hint update
				set -g __reload_pending yes
			end
		end
	end

	# when no jobs are running, consider autoupdate
	if [ "$__reload_pending" = "yes" ] \
		&& [ "$__watched_job_pids" = "" -a "$disable_autoupdate" != "yes" ]
		
		# auto-update
		echo "Autoupdate triggered! History may be merged, your most recent cmd was:"
		echo (set_color $fish_color_command)"$__saved_cmdline"(set_color $fish_color_normal)
		policeline "new fish config loaded - env reset"
		reload
	end
	
	# monitor keybinds file mtime, reload if changed
	if [ "$__sp_keybinds_mtime" != "" ]
		if [ (__sp_getmtime $__sp_keybinds_file) -ne $__sp_keybinds_mtime ]
			__sp_keybinds
		end
	end
end

function __shellpack_cmd_duration -S -d 'Show command duration'
	[ "$theme_display_cmd_duration" = "no" ]
	and return
	if [ "$argv[1]" != "" ]
		set duration "$argv[1]"
	else
		set duration "$CMD_DURATION"
	end
	[ -z "$duration" -o "$duration" -lt 100 ]
	and return
	
	echo -n (__spt duration)

	if [ "$duration" -lt 5000 ]
		echo -ns $duration 'ms'
	else if [ "$duration" -lt 60000 ]
		__shellpack_pretty_ms $duration 's'
	else if [ "$duration" -lt 3600000 ]
			set_color $fish_color_error
		__shellpack_pretty_ms $duration 'm'
	else
			set_color $fish_color_error
		__shellpack_pretty_ms $duration 'h'
	end

	set_color $fish_color_normal
	set_color $fish_color_autosuggestion

	[ "$theme_display_date" = "no" ]
	or echo -ns ' '
end

function __shellpack_pretty_ms -S -a ms -a interval -d 'Millisecond formatting for humans'
	set -l interval_ms
	set -l scale 1

	switch $interval
		case s
			set interval_ms 1000
		case m
			set interval_ms 60000
		case h
			set interval_ms 3600000
			set scale 2
	end

	echo -ns (math -s$scale "$ms/$interval_ms")
	echo -ns $interval
end

function __shellpack_timestamp -S -d 'Show the current timestamp'
	[ "$theme_display_date" = "no" ]
	and return

	set -q theme_date_format
	or set -l theme_date_format "+%c"

	set -l current_day (date $theme_date_format)
	
	echo -n " "(__spt calendar)"$current_day"

	set -q theme_time_format
	or set -l theme_time_format "+%c"

	# UTF8 clock icon here
	echo -n " "(__spt clock)
	date $theme_time_format
end

function __sp_reset_exit_status -e fish_preexec -d \
	"Reset exit status variables"
	set -e -g __saved_pipestatus
	set -e -g __saved_status
end

function __sp_reset_exit_status_on_enter -e sp_submit_commandline -d \
	"Reset exit status variables on enter"
	# needs comment: why abort when commandline is invalid? this breaks resetting the status on enter with empty commandline
	#if test (__sp_vercmp "$FISH_VERSION" '3.7.1') -ge 0 && ! commandline --is-valid
	#	return
	#end
	__sp_reset_exit_status
end

function __sp_get_pending_job_pids -d \
	"Return the last pid in each jobs process group to watch"
	for job_row in (jobs)
		set -l job_row (string split \t $job_row)
		set -l last_line ""
		for last_line in (jobs -p "%"$job_row[1] | string match -r '^[1-9]+[0-9]*$')
		end
		if [ "$last_line" != "" ]
			echo "$last_line"
		end
		#	NOTE: gid -2 exists,
		#	see: https://github.com/fish-shell/fish-shell/issues/9712
	end
end

function __sp_delay_exec_hook -e sp_submit_commandline -d \
	"Delay execution when commandline starts with @ 'timespec'"
	
	if test (__sp_vercmp "$FISH_VERSION" '3.7.1') -ge 0 && ! commandline --is-valid
		return
	end
	
	set -l cmd (commandline)
	echo "$cmd" | read -a --tokenize tokens
	
	if test "$tokens[1]" = '@'
		set -l at_time_human "$tokens[2]"
		echo ""
		if __sp_delay_exec "$at_time_human"
			# move cursor up
			echo -en '\033[1A'
			# clear line
			echo -en '\033[2K'
			# move cursor up
			echo -en '\033[1A'
			
			#set cmd (string replace --regex "^ *@.*?: *" "" -- $cmd)
			#commandline $cmd
		else
			echo ""
			echo "Usage: @ 'TIME' COMMANDLINE" >&2
			echo "" >&2
			echo "Execute COMMANDLINE at given TIME" >&2
			echo "" >&2
			echo "Examples for TIME (GNU compatible 'date'):" >&2
			echo "  14:00:00    -  execute at 14 'o clock this or next day" >&2
			echo "  '1 hour'    - execute 1 hour in the future" >&2
			echo "  'tue 01:00' -  execute Tuesday 1 o' clock" >&2
			echo "" >&2
			echo "Pipes are supported and will start on schedule:" >&2
			echo "  @ '5 seconds' echo \"print my example\" | grep \"my example\"" >&2
			commandline "  commandline "(string escape -- $cmd)
		end
	end
end

function __sp_delay_exec
	set -l at_time_human $argv
	if test "$at_time_human" = ""
		echo "Time argument missing"
		return 1
	end
	# interpret date / time
	set timestamp_target (date -d "$at_time_human" +%s) || return 4
	set timestamp_now (date +%s)
	
	# correct +1day
	if test $timestamp_target -lt $timestamp_now
		set timestamp_target (date -d "+1 day $at_time_human" +%s)
		if test $timestamp_target -lt $timestamp_now
			echo "Requested time less than now, assuming user error!"
			return 1
		end
		echo "Requested time less than now, assuming +1 day"
	end
	
	set delay (math "$timestamp_target - "(date +%s))
	echo "Delay $delay seconds until "(date -d "@$timestamp_target" "+%Y-%m-%d %H:%M:%S")" …"
	
	if test $delay -gt 2
		# cut sleep to increase precision at end with the loop below
		sleep (math "$delay - 2")
	end
	
	# synchronize to the second
	set idle 0
	while test (date +%s) -lt $timestamp_target
		set idle (math $idle + 1)
	end
end

# begin silent updates (avoid reload)

# from time to time, upgraded shells can be live patched here until a config.fish
# upgrade becomes necessary, at which point stuff gets copied over and live shells will
# reload with a policeline

if test -z "$EDITOR"
	set EDITOR "mcedit"
end

#if test "$__sp_silent_update" = "" -o "$__sp_silent_update" -lt 2
	#policeline "shell-pack silent update 1 applied"
	#set -g __sp_silent_update 2
#end


# end silent updates
