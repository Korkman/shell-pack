function __sp_cap_stat_has_c_format_w
	# busybox stat accepts -c but doesn't support %W (birth time), printing the literal letter instead
	if $__cap_stat_has_c_format && stat --help &| string match -q -- '%W'
		set -g __cap_stat_has_c_format_w true
		return 0
	else
		set -g __cap_stat_has_c_format_w false
		return 1
	end
end
