function __sp_getbtime -a file -d \
	'Get birth (creation) time of a file, empty if unsupported by the filesystem/OS'
	if $__cap_stat_has_c_format && $__cap_stat_has_c_format_w
		# GNU stat: %W is birth time epoch, or 0 if the filesystem doesn't record it
		set -l btime (stat -c '%W' "$file")
		test "$btime" != 0
		and echo "$btime"
	else if not $__cap_stat_has_c_format
		stat -f %B "$file"
	end
end
