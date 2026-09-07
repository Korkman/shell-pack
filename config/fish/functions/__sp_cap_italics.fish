function __sp_cap_italics
	if type -q tput && tput sitm &>/dev/null
		set -g __cap_italics true
		return 0
	else
		set -g __cap_italics false
		return 1
	end
end
