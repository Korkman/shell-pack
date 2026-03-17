function __sp_pid_fingerprint_kill -a pid -a fingerprint -a signal
	if test -z "$signal"
		set signal SIGTERM
	end
	# verify PID is still the same process as before
	set -l fingerprint2 (__sp_pid_fingerprint $pid)
	or return # PID already dead
	
	if test "$fingerprint" = "$fingerprint2"
		kill -$signal $pid &>/dev/null # may be dead now
	else
		echo "PID $pid fingerprint mismatch, not killing" >&2
	end
end
