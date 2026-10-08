function __sp_cap_less_has_prompt
	if command -q less && command less --help &| string match -q -- '*-P*'
		set -g __cap_less_has_prompt true
		return 0
	else
		set -g __cap_less_has_prompt false
		return 1
	end
end
