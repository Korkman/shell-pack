function fiddle -d "A 'fiddle' mode where executing a command will not clear the commandline"
	if ! set -q __sp_fiddle_mode
		set -g __sp_fiddle_mode 1
		
		# attach ctrl-c handler to exit fiddle mode intuitively
		function __sp_fiddle_ctrl_c -e fish_cancel
			if set -q __sp_fiddle_mode
				fiddle
			end
			# discard ctrl-c handler when no longer needed
			functions -e __sp_fiddle_ctrl_c
		end
		
		# save current history filter, install ours
		if functions -q fish_should_add_to_history
			functions -c fish_should_add_to_history __sp_fish_should_add_to_history_backup
		end
		function fish_should_add_to_history
			# keep no history while fiddling
			return 1
		end
		
		if test "$argv[1]" = "--instant"
			# noop when enabled during commandline editing
		else
			# read potentially multiline history content
			set -g __sp_fiddle_cmd (history --max=1 | read -zg __sp_fiddle_cmd)
			# remove trailing newlines
			set -g __sp_fiddle_cmd (string collect -- $__sp_fiddle_cmd)
			set -g __sp_fiddle_cursor 0
		end
		clear
	else
		functions -e fish_should_add_to_history
		# restore previous history filter, if any
		if functions -q __sp_fish_should_add_to_history_backup
			functions -c __sp_fish_should_add_to_history_backup fish_should_add_to_history
			functions -e __sp_fish_should_add_to_history_backup
		end
		
		set -eg __sp_fiddle_mode
		# keep the final executed command in history
		history append -- "$__sp_fiddle_cmd"
		set -eg __sp_fiddle_cmd
	end
	commandline -f repaint
	return 0
end

function __sp_fiddle_precmd -e sp_submit_commandline
	if set -q __sp_fiddle_mode
		# read potentially multiline commandline content
		commandline --current-buffer | read -zg __sp_fiddle_cmd
		# remove trailing newlines
		set -g __sp_fiddle_cmd (string collect -- $__sp_fiddle_cmd)
		# store cursor position
		set -g __sp_fiddle_cursor (commandline --cursor)
		clear
	end
end

function __sp_fiddle_postexec -e fish_postexec
	if set -q __sp_fiddle_mode
		# force print of enhanced prompt exit status line
		__sp_print_enhanced_prompt_exit_status
		# move prompt to the top
		echo -en "\r\033[H"
		commandline -- "$__sp_fiddle_cmd"
		commandline --cursor "$__sp_fiddle_cursor"
	end
end
