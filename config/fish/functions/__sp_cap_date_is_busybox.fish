function __sp_cap_date_is_busybox
	# busybox date accepts -d like GNU date, but is a distinct implementation
	if date --help 2>&1 | string match -q -- '*BusyBox*'
		set -g __cap_date_is_busybox true
		return 0
	else
		set -g __cap_date_is_busybox false
		return 1
	end
end
