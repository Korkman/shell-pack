function __sp_cap_date_is_bsd
	if date --help &| string match -q -- '*-j*'
		set -g __cap_date_is_bsd true
		return 0
	else
		set -g __cap_date_is_bsd false
		return 1
	end
end
