function __sp_cap_sed_has_l
	# BSD sed: -l for line buffered output
	# NOTE: GNU sed also accepts -l (with another meaning), so check __cap_sed_has_u first
	if echo | sed -l -e '' >/dev/null 2>&1
		set -g __cap_sed_has_l true
		return 0
	else
		set -g __cap_sed_has_l false
		return 1
	end
end
