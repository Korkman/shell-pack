function __sp_cap_wget_has_no_use_server_timestamps
	if wget --help &| string match -q -- '*--no-use-server-timestamps*'
		set -g __cap_wget_has_no_use_server_timestamps true
		return 0
	else
		set -g __cap_wget_has_no_use_server_timestamps false
		return 1
	end
end
