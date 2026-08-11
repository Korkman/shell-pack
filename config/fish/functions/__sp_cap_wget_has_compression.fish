function __sp_cap_wget_has_compression
	if command wget --help &| string match -q -- '*--compression=*'
		set -g __sp_cap_wget_has_compression true
		return 0
	else
		set -g __sp_cap_wget_has_compression false
		return 1
	end
end
