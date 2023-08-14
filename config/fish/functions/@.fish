function @ \
	-d 'Execute command at a given time as if typed into the prompt'
	if test (count $argv) -lt 2
		echo "Usage: @ TIME COMMAND ...ARGS" >&2
		echo "" >&2
		echo "Execute COMMAND with optional arguments ARGS at given TIME as if typed into the prompt" >&2
		echo "" >&2
		echo "Examples for TIME (GNU compatible 'date'):" >&2
		echo "  14:00:00    -  execute at 14 'o clock this or next day" >&2
		echo "  '+1 hour'   -  execute 1 hour in the future" >&2
		echo "  'tue 01:00' -  execute Tuesday 1 o' clock" >&2
		echo "" >&2
		echo "Enclose pipes into quotes to execute them as a whole:" >&2
		echo "  @ '+5 seconds' 'echo \"example\" | grep example'" >&2
		return 2
	end

	if ! isatty stdout || ! isatty stdin
		echo "ERROR: Do not place '@' in a pipe." >&2
		echo "Instead, enclose the entire pipe with quotes to make it a single commandline which will" >&2
		echo "execute at the given time." >&2
		return 3
	end

	if test "$TMUX" = ""
		echo "WARNING: you are not in tmux and this is not 'atd'. Losing connection will abort your command!"
	end

	set at_time_human "$argv[1]"
	set command_and_args $argv[2..-1]

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
	echo "Sleeping $delay seconds ..."
	
	if test $delay -gt 2
		# cut sleep to increase precision at end with the loop below
		sleep (math "$delay - 2")
	end

	# synchronize to the second
	set idle 0
	while test (date +%s) -lt $timestamp_target
		set idle (math $idle + 1)
	end

	commandline "$command_and_args"
	commandline -f "execute"
end
