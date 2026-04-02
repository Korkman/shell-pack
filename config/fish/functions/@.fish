function @ -d \
	'Delay execution until a given time'
	
	if ! $__cap_date_is_gnu && ! $__cap_date_is_bsd
		# TODO: double-check if busybox date can be used in any sane way
		echo "Unsupported date command, cannot do date math" >&2
		return 3
	end
	
	if test "$argv" = ""
		echo "Usage: @ TIME [... TIME] [ -- COMMAND ]"
		echo ""
		echo "Delay until given TIME, then execute COMMAND if passed after '--'."
		echo "Interpreter for COMMAND is FISH."
		echo "An effort was made to hit the precise second specified."
		echo ""
		if $__cap_date_is_gnu
			echo "TIME is interpreted with GNU date, see 'date --help' for details."
			echo "Examples for TIME (GNU compatible 'date'):"
			echo "  14:30:00          - execute at 14:30:00 this or next day"
			echo "  1 hour 20 minutes - execute in 1 hour and 20 minutes"
			echo "  tue 01:00:00      - execute tuesday at 1 AM"
			echo ""
			echo "Usage without passing a COMMAND:"
			echo "  @ 5 seconds; echo 123"
		else if $__cap_date_is_bsd
			echo "TIME is interpreted with BSD date '-v' arguments, see 'man date' for details."
			echo "Examples for TIME (BSD compatible 'date'):"
			echo "  14H 30M 00S  - execute at 14:30:00 this or next day"
			echo "  +1H +20M     - execute in 1 hour and 20 minutes"
			echo "  2w 1H 0M 0S  - execute tuesday at 1 AM"
			echo ""
			echo "Usage without passing a COMMAND:"
			echo "  @ +5S; echo 123"
		end
		
		return 1
	end >&2
	
	set -l at_time_human
	
	while test (count $argv) -gt 0
		if test "$argv[1]" = "--"
			set -e argv[1]
			break
		end
		set -a at_time_human "$argv[1]"
		set -e argv[1]
	end
	
	set -l explicit_command "$argv"
	
	if test "$at_time_human" = ""
		echo "Time argument missing"
		return 1
	end
	
	set timestamp_now (date +%s) || return 5
	
	# interpret date / time
	if $__cap_date_is_gnu
		set timestamp_target (date -d "$at_time_human" +%s) || return 4
		if test $timestamp_target -lt $timestamp_now
			# add +1day if in the past
			echo "Requested starting time in the past, assuming +1 day …"
			set timestamp_target (date -d "+1 day $at_time_human" +%s)
		end
		set human_timestamp_target (date -d "@$timestamp_target")
	else if $__cap_date_is_bsd
		set -l date_cmd 'date' '-j'
		for arg in $at_time_human
			set -a date_cmd "-v$arg"
		end
		set timestamp_target ($date_cmd +%s) || return 4
		if test $timestamp_target -lt $timestamp_now
			# add +1day if in the past
			echo "Requested starting time in the past, adding up to 7 days …"
			set -l limit 7
			set -l timestamp_start (date -j -v+1d +%s)
			while test $timestamp_target -lt $timestamp_now && test $limit -gt 0
				set timestamp_start (date -j -f%s -v+1d $timestamp_start +%s)
				set timestamp_target ($date_cmd -f%s $timestamp_start +%s)
				set limit (math $limit - 1)
			end
		end
		set human_timestamp_target (date -j -f%s $timestamp_target)
	end
	
	if test $timestamp_target -lt $timestamp_now
		echo "Requested time too far in the past, assuming user error!" >&2
		return 1
	end
	
	set delay (math "$timestamp_target - "(date +%s))
	echo "Delay $delay seconds until $human_timestamp_target …"
	
	if test $delay -gt 3
		# cut sleep to increase precision at end with the hot loop below
		sleep (math "$delay - 3")
	end
	
	# synchronize to the second in a hot loop, to be as precise as possible
	set idle 0
	while test (date +%s) -lt $timestamp_target
		set idle (math $idle + 1)
	end
	
	if test "$explicit_command" != ""
		eval $explicit_command
	end
end
