function __sp_cap_wget_has_max_redirect
	if wget --help &| string match -q -- '*--max-redirect*'
		set -g __cap_wget_has_max_redirect true
		return 0
	else
		set -g __cap_wget_has_max_redirect false
		return 1
	end
end
