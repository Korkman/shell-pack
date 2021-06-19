function __sp_set_timer -a timer_name timer_seconds
	# dynamic variable name to store ticks to pass until timer fires
	set -l tick_var "__sp_timer_ticks_$timer_name"
	set -l tick_interval "0.5"
	# calculate ticks to pass based on tick interval
	set -l ticks_to_pass (math "ceil($timer_seconds / $tick_interval)")
	# set global countdown variables
	set -g $tick_var $ticks_to_pass
	set -l ticks_until_pulse_kill (math "ceil($ticks_to_pass + 10 / $tick_interval)")
	if ! set -q __sp_ticks_until_pulse_kill || test "$ticks_until_pulse_kill" -gt "$__sp_ticks_until_pulse_kill"
		# delayed kill of pulse
		set -g __sp_ticks_until_pulse_kill $ticks_until_pulse_kill
	end
	
	# add timer name to list of names
	if ! contains -- "$timer_name" $__sp_timer_names
		set -ga __sp_timer_names "$timer_name"
	end
	
	if ! set -q __sp_timer_pulse_pid

		__sp_timer_start_pulse

	end
end

function __sp_timer_check_pulse --on-event fish_postexec -d \
	'Check pulse: is the background timer running correctly?'
	if set -q __sp_timer_pulse_pid
		# find matching pid in ppid group, otherwise cancel pending timers && remove pid information
		if ! ps o pid,ppid | string match -q --regex "[^0-9]*""$__sp_timer_pulse_pid""[^0-9]+""$fish_pid"
			# restart pulse subprocess
			#echo "debug: Timer pulse bg process restarting"
			__sp_timer_start_pulse
		end
	end
end

function __sp_timer_start_pulse -d \
	'Start pulse subprocess'
	set -l tick_interval '0.5'
	# start the pulse, sending a SIGUSR1 to this PID every $tick_interval in background
	# cd / so the subprocess won't block mounts
	sh -c "cd /; c=0; trap 'noop=1' INT; trap 'c=0' USR1; while [ \$c -lt 60 ]; do sleep $tick_interval; kill -s USR1 $fish_pid || exit 0; c=\$(( c + 1 )); done; exit 0" > /dev/null 2>&1 < /dev/null &
	# store and disown the pid
	set -g __sp_timer_pulse_pid (jobs --last --pid)
	disown $__sp_timer_pulse_pid

	set -g __sp_ticks_since_pulse_refresh 0

	# ready function to kill the PID on exit
	function __sp_timer_kill_pulse --on-event fish_exit
		if ! set -q __sp_timer_pulse_pid; return; end
		#echo "Killing timer pulse PID $__sp_timer_pulse_pid"
		
		# find matching pid in ppid group, otherwise abort kill
		if ps o pid,ppid | string match -q --regex "[^0-9]*""$__sp_timer_pulse_pid""[^0-9]+""$fish_pid"
			kill $__sp_timer_pulse_pid || echo "It seems a race occured stopping the timer pulse subprocess with kill"
		else
			# this is a normal thing now
			#echo "Warning: Timer pulse bg process lost!"
		end
		set -ge __sp_timer_pulse_pid
	end
end

function __sp_timer_pulse -s SIGUSR1
	for timer_name in $__sp_timer_names
		set -l tick_var "__sp_timer_ticks_$timer_name"
		set -g $tick_var (math "$$tick_var - 1")
		if test "$$tick_var" -le 0
			#echo "time up: $timer_name"
			emit "sp_timer_$timer_name"
			# remove timer name from list
			set -ge __sp_timer_names[(contains --index -- $timer_name $__sp_timer_names)]
			# remove timer countdown variable
			set -ge $tick_var
		end
	end
	
	if ! set -q __sp_timer_pulse_pid
		# if this variable does not exist, we received a SIGUSR1 without tracking the actual PID
		# this may happen occasionally, when __sp_ticks_until_pulse_kill overlaps with received signal?
		#echo "debug: Rogue pulse received (signal SIGUSR1 from untracked PID)"
	else
		# garbage collect pulse PID
		set -g __sp_ticks_until_pulse_kill (math "$__sp_ticks_until_pulse_kill - 1")
		if test "$__sp_timer_names" = "" && test "$__sp_ticks_until_pulse_kill" -le 0
			__sp_timer_kill_pulse
		end
		# refresh pulse process
		set -g __sp_ticks_since_pulse_refresh (math "$__sp_ticks_since_pulse_refresh + 1")
		if test $__sp_ticks_since_pulse_refresh -gt 40
			__sp_timer_refresh_pulse
		end
	end
	
end

function __sp_timer_refresh_pulse -d \
	'Send a SIGUSR1 to the pulse subprocess to refresh its self-termination countdown'
	if ! set -q __sp_timer_pulse_pid; return; end
	
	set -g __sp_ticks_since_pulse_refresh 0

	#echo "debug: refreshing pulse"
	if ps o pid,ppid | string match -q --regex "[^0-9]*""$__sp_timer_pulse_pid""[^0-9]+""$fish_pid"
		#echo "debug: refreshing pulse!"
		kill -s USR1 $__sp_timer_pulse_pid || echo "It seems a race occured when sending USR1 to the timer pulse subprocess"
	end
end
