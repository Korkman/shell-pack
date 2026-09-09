function __sp_cap_timeout_has_t
	if command -q timeout && command timeout --help &| string match -qr -- '(^|[^-\w])-t([^-\w]|$)'
		set -g __cap_timeout_has_t true
		return 0
	else
		set -g __cap_timeout_has_t false
		return 1
	end
end