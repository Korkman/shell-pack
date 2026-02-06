function __sp_cap_less_has_mouse
	if command -q less && command less --help &| string match -q -- '*--mouse*'
		set -g __cap_less_has_mouse true
		return 0
	else
		set -g __cap_less_has_mouse false
		return 1
	end
end
