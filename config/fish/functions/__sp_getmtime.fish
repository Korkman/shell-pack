function __sp_getmtime -a file -d \
	'Get modification time of a file'
	if $__cap_ls_has_time_style
		set -l output (command ls -nl --time-style=+%s "$file" | string split --no-empty ' ')
		and echo "$output[6]"
	else if $__cap_stat_has_printf
		stat --printf '%Y' "$file"
	else
		stat -f %m "$file"
	end
end
