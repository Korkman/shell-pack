function __cap_ps_has_start
	if ps -p $fish_pid -o start= &>/dev/null
		set -g __cap_ps_has_start true
		return 0
	else
		set -g __cap_ps_has_start false
		return 1
	end
end
