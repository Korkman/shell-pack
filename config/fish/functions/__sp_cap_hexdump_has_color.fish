function __sp_cap_hexdump_has_color
	if command -q hexdump
		set -l help_text (hexdump --help 2>&1)
		if string match -q -- '*--color*' $help_text
			set -g __cap_hexdump_has_color true
			return 0
		end
	end
	set -g __cap_hexdump_has_color false
	return 1
end
