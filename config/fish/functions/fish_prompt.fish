function fish_prompt -d "powerline-go like prompt"
	if [ (status function) = "fish_prompt_mc" ]
		# this function was copied and renamed by mc to fish_prompt_mc
		
		# terrible bug in Debian Stretch: an additional prompt line!
		# lets remove it
		set -l wrapped_prompt
		begin
			set -l IFS ''
			set wrapped_prompt (functions fish_prompt)
		end
		
		# detect if the new fish_prompt contains the bugged line
		if string match --quiet "*echo (whoami)*" -- $wrapped_prompt
			set -l new_prompt (string replace --regex '.*echo \(whoami\)[^;]+' '' -- $wrapped_prompt)
			eval $new_prompt
		end
		
		# also, it is likely mc spammed the history, so we erase it immediately
		# (Debian Jessie and Stretch affected, fixed in Buster)
		if ! set -q __mc_history_cleared
			set -g __mc_history_cleared yes
			echo "all" | history delete --prefix "if not functions -q fish_prompt_mc;" &> /dev/null
		end
	end
	

	if set -q __skip_prompt
		set -e __skip_prompt
		return
	end
	
	__update_glyphs
	
	fish_prompt_reset_segments
	set pwd_budget 40
	if ! functions -q fish_right_prompt
		# left-hand versions of right prompt segments
		
		# backgrounded jobs
		if jobs -q
			set ijobs (jobs -g)
			set njobs (count $ijobs)
			if [ $njobs -lt 4 ]
				fish_prompt_segment "bryellow" "black" "$running_glyph "(string join ' ' $ijobs)
			else
				fish_prompt_segment "bryellow" "black" "$running_glyph x$njobs"
			end
		end
		
		# reload pending segment
		if [ "$__reload_pending" = "yes" ]
			fish_prompt_segment "eee" "f00" "New FISH! Reload!"
		end
	end
	
	if [ "$debian_chroot" != "" ]
		# autotag with $debian_chroot
		set -l chroot_tag "($debian_chroot)"
		fish_prompt_shorten_string chroot_tag 12
		__fish_prompt_reduce_pwd_budget chroot_tag
		fish_prompt_segment "000" "fff" "$chroot_tag"
	end

	if [ "$__session_tag" != "" ]
		set visual_session_tag "$__session_tag"
		fish_prompt_shorten_string visual_session_tag 20
		# subtract taken space from pwd budget
		__fish_prompt_reduce_pwd_budget visual_session_tag
		fish_prompt_segment "ff0" "000" "$tag_glyph""$visual_session_tag"
	else
	end
	
	if [ ! -z "$fish_private_mode" ]
		if [ "$theme_nerd_fonts" = "yes" ]
			set symbol \ufaf8
		else
			set symbol '!'
		end
		fish_prompt_segment "purple" "white" "$symbol"
	end
	
	if [ "$PWD" = "/" ]
		# special case root-dir
		fish_prompt_segment "3a3a3a" "fff" "/"
	else
		# find longest matching tagged dir
		set matched_len_tagged_dir_path 0
		set -ge matched_tagged_dir_name
		for tagged_dir in $__tagged_dirs
			set tagged_dir_path "$__tagged_dirs_path_list[$tagged_dir]"
			set tagged_dir_name "$__tagged_dirs_name_list[$tagged_dir]"
			set len_tagged_dir_path (string length "$tagged_dir_path")
			if [ $len_tagged_dir_path -gt $matched_len_tagged_dir_path -a (string sub --start 1 --length $len_tagged_dir_path "$PWD") = "$tagged_dir_path" ]
				set matched_len_tagged_dir_path $len_tagged_dir_path
				set matched_tagged_dir_path "$tagged_dir_path"
				set -g matched_tagged_dir_name "$tagged_dir_name"
			end
		end
		
		set len_home (string length "$HOME")
		if [ "$matched_tagged_dir_path" != "" ]
			set visual_pwd (string sub --start (math $matched_len_tagged_dir_path + 1) "$PWD")
			fish_prompt_segment "0087af" "fff" "$bookmark_glyph""$matched_tagged_dir_name"
		else if [ $len_home -gt 0 -a (string sub --start 1 --length $len_home "$PWD") = "$HOME" ]
			# home indicator
			# prefix replace ~
			set visual_pwd (string sub --start (math $len_home + 1) "$PWD")
			fish_prompt_segment "0087af" "fff" "$home_glyph"
		else
			set visual_pwd "$PWD"
		end
		
		if [ "$visual_pwd" != "" ]
			fish_prompt_shorten_path visual_pwd $pwd_budget
			if [ "$theme_powerline_fonts" = "no" ]
				# simply leave slashes as-is with no powerline fonts
				fish_prompt_segment "3a3a3a" "fff" "$visual_pwd"
			else
				# split into segments
				set visual_pwd (string trim --left --chars '/' "$visual_pwd")
				set path_segments (string split '/' $visual_pwd)
				set cnt_path_segments (count $path_segments)
				set idx_path_segments 0
				for path_segment in $path_segments
					set idx_path_segments (math $idx_path_segments + 1)
					if [ $idx_path_segments -eq $cnt_path_segments ]
						set segment_color "fff"
					else
						set segment_color "bbb"
					end
					fish_prompt_segment "3a3a3a" "$segment_color" "$path_segment" "888"
				end
			end
		end
	end
	
	# lock-icon for write-protected
	if [ ! -w "$PWD" ]
		fish_prompt_segment "711" "fff" "$lock_glyph"
	end
	
	fish_prompt_print_segments
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
	set pwd_budget (math $pwd_budget - (math 100 / $COLUMNS x (string length "$$argv[1]")))
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
	set --local dim_fgcolor "$fgcolor"
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
		set_color -b $bgcolor
		if [ $segment -gt 1 ]
			if [ "$bgcolor" = "$prev_bgcolor" ]
				set_color $dim_fgcolor
				echo -n "$right_arrow_glyph"
			else
				set_color $prev_bgcolor
				echo -n "$right_black_arrow_glyph"
			end
		end
		set_color $fgcolor
		echo -n -- "$space""$__fish_prompt_segments_content_list[$segment]""$space"
		
		set prev_bgcolor $bgcolor
	end
	set_color normal
	set_color $prev_bgcolor
	echo -n "$right_black_arrow_glyph"
	set_color normal
	echo -n "$space"
end

function __shellpack_get_string_term_lines -d "Return count of terminal lines a string approx. uses to display with current prompt"
	set -l linesburned 0
	
	# calculate approx. promptlength (some ultra-wide / invisible utf-8 chars will mess this up)
	set -l promptlength (fish_prompt | string replace -ra '\e\[[^m]*m' '' | string length)
	
	# walk all actual lines in input
	while read -l line
		set -l this_line_length (string length "$line")
		set linesburned (math "$linesburned + ceil(($this_line_length + $promptlength - 1) / $COLUMNS)")
	end
	
	echo $linesburned
end

function __shellpack_erase_command_lines -d "Try to erase all lines a typed cmd took to display, assuming cursor is at the end"
		__shellpack_get_string_term_lines | read linesburned
		#set -l linesburned (cat | __shellpack_get_string_term_lines)
		for i in (seq 1 $linesburned)
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
	if [ (string length "$__new_cmdline") -gt 1 -a (string sub -s 1 -l 1 "$__new_cmdline") = " " -a (string sub -s 1 -l 2 "$__new_cmdline") != "  " ]
		echo "$argv[1]" | __shellpack_erase_command_lines
		# reminder to clear history
		__update_glyphs
		fish_prompt_reset_segments
		if [ "$theme_nerd_fonts" = "yes" ]
			set symbol \ufaf8
		else
			set symbol '!'
		end
		fish_prompt_segment "purple" "white" "$symbol"
		fish_prompt_print_segments
		echo "Private history: 'up' to edit. Solo space or other cmd clears."
		set -g __shellpack_current_cmd_confidential yes
	else
		set -g __shellpack_current_cmd_confidential no
	end
end

function enhanced_prompt -e fish_postexec -d "Foreground and background job execution tracking and status code clearance"
	set -g __saved_pipestatus (string split ' ' "$pipestatus")
	# NOTE: $status is gone at this point
	set -g __saved_status $__saved_pipestatus[(count $__saved_pipestatus)]
	set -g __saved_duration "$CMD_DURATION"
	set -x __job_start_time (__sp_getnanoseconds)
	set -g __saved_cmdline (echo "$argv[1]" | string replace "\n" " ")
	if [ "$argv[1]" = " __shell_pack_clear_status_subroutine" ]
		# move cursor one line up to overwrite __shell_pack_clear_status_subroutine
		echo -en '\033[1A'
		return
	end
	if [ "$argv[1]" = " " ]
		# move cursor one line up to overwrite __shell_pack_clear_status_subroutine's solo space execution
		echo -en '\033[1A'
		return
	end
	
	__update_glyphs
	
	# detect tracked, but lost jobs (e.g. by kill)
	if [ "$__watched_job_pids" != "" ]
		for job_pid in $__watched_job_pids
			if ! [ -e /proc/$job_pid ]
				job_watcher$job_pid "KILLED?" 0 -2
			end
		end
	end
	
	# detect new untracked jobs
	if jobs -q
		#set new_bg_tasks ""
		for job_pid in (jobs -g)
			if ! functions -q job_watcher$job_pid
				# untracked backgrounded task detected
				set -g __watched_job_pids $__watched_job_pids $job_pid
				set new_bg_tasks $job_pid $new_bg_tasks
				function job_watcher$job_pid -V job_pid -V __job_start_time -V __saved_cmdline --on-process-exit $job_pid
					# remove my pid from list
					set -ge __watched_job_pids[(contains -i $job_pid $__watched_job_pids)]
					__update_glyphs

					set job_status $argv[3]
					set duration (math "round(("(__sp_getnanoseconds)" - $__job_start_time ) / 1000 / 1000)")

					echo
					set_color -b bryellow
					set_color black
					if [ (string length "$__saved_cmdline") -gt 20 ]
						echo -n ' '(string sub -l 9 "$__saved_cmdline")'…'(string sub -s -9 "$__saved_cmdline")' '
					else
						echo -n " "$__saved_cmdline" "
					end
					set_color normal
					set_color bryellow
					echo -n "$right_black_arrow_glyph "
					if [ $job_status -eq 0 ]
						set_color "0b0"
						echo -n "$happy_glyph "
					else
						set_color "c00"
						echo -n "$unhappy_glyph $job_status "
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
				set plural jobs
			else
				set plural job
			end
			set_color -b bryellow
			set_color black
			echo -en " $running_glyph "
			set_color normal
			set_color bryellow
			echo -en "$right_black_arrow_glyph"
			set_color normal
			echo " New $plural $new_bg_tasks"
		end
	end

	# ignore empty lines and backgrounding tasks
	if [ "$__saved_cmdline" != "" ]
		if [ (string trim (string sub -s -1 -l 1 "$__saved_cmdline")) = "&" ]
			# command ends in & means a task was backgrounded - assuming $status is misleading
			echo
		else
			set -g __display_cmd_stats yes

			# output cmd
			if [ $__saved_status -eq 0 ]
				set thisbg "171"
				set thisfg "fff"
			else
				set thisbg "711"
				set thisfg "fff"
			end
			set_color -b $thisbg
			set_color $thisfg
			if [ "$__shellpack_current_cmd_confidential" = "yes" ]
				if [ "$theme_nerd_fonts" = "yes" ]
					echo -n ' '\ufaf8' '
				else
					echo -n ' ! '
				end
			else
				if [ (string length "$__saved_cmdline") -gt 40 ]
					echo -n ' '(string sub -l 19 "$__saved_cmdline")'…'(string sub -s -19 "$__saved_cmdline")' '
				else
					echo -n " "$__saved_cmdline" "
				end
			end
			set_color -b normal
			set_color $thisbg
			echo -n "$right_black_arrow_glyph "

			if [ $__saved_status -eq 0 ]
				set_color "0b0"
				echo -n "$happy_glyph "
			else
				set_color "c00"
				# ring the bell
				echo -n \a
				echo -n "$unhappy_glyph ""$__saved_status "
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
					set thisbg "711"
					set thisfg "fff"
					set_color -b $thisbg
					set_color $thisfg
					echo -n " Non-zero exit status in pipe "
					set_color normal
					set_color $thisbg
					echo -n "$right_black_arrow_glyph "
					set forcount 0
					for substatus in $__saved_pipestatus
						set forcount (math $forcount + 1)

						if [ $substatus -gt 0 ]
							set_color "b00"
						else
							set_color "0b0"
						end
						echo -n "$substatus "
						if [ $forcount -lt (count $__saved_pipestatus) ]
							set_color $fish_color_autosuggestion
							echo -ne "$right_arrow_glyph "
						end
					end
					set_color normal
					echo
				end
			end
			
			if [ (string sub -s 1 -l 1 "$__saved_cmdline") != " " -a $__saved_status -ne 0 ]
				# feature: set $status to 0 for consistency (try 'set x 1')
				# except for space-prefix, so one-line history still works
				__shell_pack_clear_status
			end
			
			if [ (string sub -s 1 -l 2 "$__saved_cmdline") = "  " ]
				# feature: double-space prefix to prevent both in-memory and persistant history
				if [ $__saved_status -ne 0 ]
					__shell_pack_clear_status
				else
					commandline --replace " "
					commandline -f execute
				end
				if [ "$theme_nerd_fonts" = "yes" ]
					echo -n \ufb8f' '
				end
				echo "Dangerous cmd flushed from history"
			else if [ (string length "$__saved_cmdline") -gt 1 -a (string sub -s 1 -l 1 "$__saved_cmdline") = " " ]
				# reminder to clear history
				#if [ "$theme_nerd_fonts" = "yes" ]
				#	echo -n \ufaf8' '
				#end
				#echo "Private history: 'up' to edit. Solo space or other cmd clears."
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
	
	# when no jobs are running, consider autoupdate
	if [ "$__sp_config_fish_file" = "" ] || [ (__sp_getmtime $__sp_config_fish_file) -ne $__sp_config_fish_mtime ]
		if [ "$__watched_job_pids" = "" -a "$disable_autoupdate" != "yes" ]
			# auto-update
			policeline "new fish config loaded - env reset"
			reload
		else
			# hint update
			set -g __reload_pending yes
		end
	end
end

function __shell_pack_clear_status -d "reset the exit status to zero"
	set -g __skip_prompt 1
	set -g __skip_right_prompt 1
	# execute __shell_pack_clear_status_subroutine outside history
	commandline --replace " __shell_pack_clear_status_subroutine"
	commandline -f execute
end

function __shell_pack_clear_status_subroutine
	set -g __skip_prompt 1
	set -g __skip_right_prompt 1
	# execute __shell_pack_clear_status_subroutine outside history
	commandline --replace " "
	commandline -f execute
	return 0
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
	
	if [ "$theme_nerd_fonts" = "yes" ]
		# glyphs with some space
		echo -n ' '\uf253' '
	else
		echo -n '  '
	end

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

	if [ "$theme_nerd_fonts" = "yes" ]
		# glyphs with some space
		set __calendar_glyph \uf455" "
		set __clock_glyph \uf43a" "
	else
		set __calendar_glyph ""
		set __clock_glyph ""
	end
	
	echo -n " $__calendar_glyph$current_day"

	set -q theme_time_format
	or set -l theme_time_format "+%c"

	# UTF8 clock icon here
	echo -n " $__clock_glyph"
	date $theme_time_format
end

