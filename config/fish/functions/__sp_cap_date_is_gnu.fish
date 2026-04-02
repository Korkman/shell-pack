function __sp_cap_date_is_gnu
	if date --help &| string match -q -- '*--date*'
		set -g __cap_date_is_gnu true
		return 0
	else
		set -g __cap_date_is_gnu false
		return 1
	end
end
