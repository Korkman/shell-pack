function __sp_cap_wget_has_verbose
	if wget --help &| string match -q -- '*--verbose*'
		set -g __cap_wget_has_verbose true
		return 0
	else
		set -g __cap_wget_has_verbose false
		return 1
	end
end
