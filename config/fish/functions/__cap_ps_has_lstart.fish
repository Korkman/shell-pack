function __cap_ps_has_lstart
	if ps -p $fish_pid -o lstart= &>/dev/null
		set -g __cap_ps_has_lstart true
		return 0
	else
		set -g __cap_ps_has_lstart false
		return 1
	end
end
