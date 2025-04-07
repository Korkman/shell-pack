function fiddle -d "A 'fiddle' mode where executing a command will not clear the commandline"
	if ! set -q __sp_fiddle_mode
		set -g __sp_fiddle_mode 1
		if test "$argv[1]" = "--instant"
			# noop when enabled during commandline editing
		else
			# read potentially multiline history content
			set -g __sp_fiddle_cmd (history --max=1 | read -zg __sp_fiddle_cmd)
			# remove trailing newlines
			set -g __sp_fiddle_cmd (string collect -- $__sp_fiddle_cmd)
			set -g __sp_fiddle_cursor 0
		end
		builtin history merge
		clear
	else
		set -e -g __sp_fiddle_mode
		set -e -g __sp_fiddle_cmd
		# TODO: utilize fish_should_add_to_history once fish 4.x is deployed more widely
		read -l -P "Discard history created in fiddle mode? (Y/n) " REPLY
		or set -l REPLY "n"
		if test "$REPLY" = "Y" -o "$REPLY" = "y" -o "$REPLY" = ""
			builtin history clear-session
		end
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
		# move prompt to the top
		echo -en "\r\033[H"
		commandline -- "$__sp_fiddle_cmd"
		commandline --cursor "$__sp_fiddle_cursor"
	end
end
