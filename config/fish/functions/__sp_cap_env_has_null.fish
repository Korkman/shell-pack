function __sp_cap_env_has_null
	if command env --help &| string match -q -- '*--null*'
		set -g __cap_env_has_null true
		return 0
	else
		set -g __cap_env_has_null false
		return 1
	end
end
