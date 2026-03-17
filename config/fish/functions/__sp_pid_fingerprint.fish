function __sp_pid_fingerprint -a pid -d \
	"Return an OS specific 'best-effort fingerprint' for a PID so that we can verify it's the same process later. Output is digits, dash, digits."
	echo -n $pid"-"
	if $__cap_proc_pid_stat
		# when on Linux, we can use the process start time from /proc as a fingerprint
		# care must be taken to skip the comm field which may contain hostile characters
		# NOTE: there is a race here between test and reading stat. if the process dies in-between, fish will print an error.
		#       `cat` could be used instead, but that would be a subprocess.
		if ! test -e /proc/$pid/stat
			# PID is dead
			echo "000000"
			return 1
		end
		string join ' ' < /proc/$pid/stat | string replace --regex '.*\) ' '' | string split -f20 ' ' | string replace -a --regex '[^0-9]' ''
	else if $__cap_ps_has_lstart
		# fallback 1: we ask ps which supports -p and -o lstart and keep only digits of the start datetime
		if ! set -l val (LC_ALL=C ps -p $pid -o lstart= 2>/dev/null)
			echo "000000"
			return 1
		end
		echo "$val" | string replace -a --regex '[^0-9]' ''
	else if $__cap_ps_has_start
		# fallback 2: we ask ps which supports -p and -o start and keep only digits of the start time
		if ! set -l val (LC_ALL=C ps -p $pid -o start= 2>/dev/null)
			echo "000000"
			return 1
		end
		echo "$val" | string replace -a --regex '[^0-9]' ''
	else
		# fallback 3: very strange environment?
		# can only append zeroes to the pid for "no idea"
		echo "000000"
	end
	return 0
end
