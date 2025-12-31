function __sp_cap_stat_has_printf
	if command stat --help &| string match -q -- '*--printf*'
		set -g __cap_stat_has_printf true
		return 0
	else
		set -g __cap_stat_has_printf false
		return 1
	end
end
