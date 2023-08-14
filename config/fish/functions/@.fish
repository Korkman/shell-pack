#! /usr/bin/fish
function @ \
	-d 'Execute command at a given time'
	if test (count $argv) -lt 2
		echo "Usage: @ TIME COMMAND ...ARGS"
		echo "Execute COMMAND with optional arguments ARGS at given TIME as if entered in the prompt"
		echo "Examples for TIME (GNU compatible 'date'):"
		echo "  14:00:00    -  execute at 14 'o clock this or next day"
		echo "  '+1 hour'   -  execute 1 hour in the future"
		echo "  'tue 01:00' -  execute Tuesday 1 o' clock"
		exit 2
	end

	if test "$TMUX" = ""
		echo "WARNING: you are not in tmux and this is not 'atd'. Losing connection will abort your command!"
	end

	set at_time_human "$argv[1]"
	set command_and_args $argv[2..-1]

	# interpret date / time
	set timestamp_target (date -d "$at_time_human" +%s)
	set timestamp_now (date +%s)

	# correct +1day
	if test $timestamp_target -lt $timestamp_now
		set timestamp_target (date -d "+1 day $at_time_human" +%s)
		if test $timestamp_target -lt $timestamp_now
			echo "Requested time less than now, assuming user error!"
			exit 1
		end
		echo "Requested time less than now, assuming +1 day"
	end
	
	set delay (math "$timestamp_target - "(date +%s))
	echo "Sleeping $delay seconds ..."

	# cut sleep to increase precision at end with the loop below
	sleep (math "$delay - 2")

	# synchronize to the second
	set idle 0
	while test (date +%s) -lt $timestamp_target
		set idle (math $idle + 1)
	end

	commandline "$command_and_args"
	commandline -f "execute"
end
