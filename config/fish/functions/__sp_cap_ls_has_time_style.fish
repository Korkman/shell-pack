function __sp_cap_ls_has_time_style
	if command ls --help &| string match -q -- '*--time-style*'
		set -g __cap_ls_has_time_style true
		return 0
	else
		set -g __cap_ls_has_time_style false
		return 1
	end
end
