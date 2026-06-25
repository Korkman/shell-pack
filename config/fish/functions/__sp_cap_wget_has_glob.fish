function __sp_cap_wget_has_glob
	if command wget --help &| string match -q -- '*--no-glob*'
		set -g __cap_wget_has_glob true
		return 0
	else
		set -g __cap_wget_has_glob false
		return 1
	end
end
