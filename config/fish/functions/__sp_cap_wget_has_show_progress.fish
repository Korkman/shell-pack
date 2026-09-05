function __sp_cap_wget_has_show_progress
	if wget --help &| string match -q -- '*--show-progress*'
		set -g __cap_wget_has_show_progress true
		return 0
	else
		set -g __cap_wget_has_show_progress false
		return 1
	end
end
