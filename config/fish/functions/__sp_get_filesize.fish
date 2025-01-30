function __sp_get_filesize -a file -d \
	'Get filesize in bytes'
	if $__cap_stat_has_printf
		stat --printf '%s' "$file"
	else
		stat -f %z "$file"
	end

end