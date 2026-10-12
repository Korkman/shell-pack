function __sp_cap_ssh_has_g
	# -F /dev/null avoids side effects of user config (e.g. Match exec)
	if command -q ssh && command ssh -F /dev/null -G localhost &>/dev/null
		set -g __cap_ssh_has_g true
		return 0
	else
		set -g __cap_ssh_has_g false
		return 1
	end
end
