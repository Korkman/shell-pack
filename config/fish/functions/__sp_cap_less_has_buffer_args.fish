function __sp_cap_less_has_buffer_args
	if command -q less
		set -l help_text (command less --help 2>&1)
		if string match -q -- '*--buffers*' $help_text && string match -q -- '*--auto-buffers*' $help_text
			set -g __cap_less_has_buffer_args true
			return 0
		end
	end
	set -g __cap_less_has_buffer_args false
	return 1
end
