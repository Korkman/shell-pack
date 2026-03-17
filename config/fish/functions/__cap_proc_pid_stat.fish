function __cap_proc_pid_stat
	if test -e /proc/self/stat
		set -g __cap_proc_pid_stat true
		return 0
	else
		set -g __cap_proc_pid_stat false
		return 1
	end
end
