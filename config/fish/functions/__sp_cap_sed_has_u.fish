function __sp_cap_sed_has_u
	# GNU sed: -u for unbuffered output
	if echo | sed -u -e '' >/dev/null 2>&1
		set -g __cap_sed_has_u true
		return 0
	else
		set -g __cap_sed_has_u false
		return 1
	end
end
