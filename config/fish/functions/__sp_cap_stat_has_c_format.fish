function __sp_cap_stat_has_c_format
	if stat --help &| string match -q --regex -- '^\s*-c\b'
		set -g __cap_stat_has_c_format true
		return 0
	else
		set -g __cap_stat_has_c_format false
		return 1
	end
end
