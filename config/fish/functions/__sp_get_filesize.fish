function __sp_get_filesize -a file -d \
	'Get filesize in bytes, accepts file descriptors, may return -1 for INFINITY or -2 for error'
	# fast path: `ls -L` dereferences symlinks (e.g. /dev/stdin -> a real
	# file), so this alone handles plain files and symlinks to files. pipe
	# into `read`, not a `(...)` command substitution: fish loses the
	# redirected stdin for substitutions run inside a function called as
	# `fn < file`, which breaks /dev/stdin lookups
	set -l output
	command ls -nlL "$file" 2>/dev/null | read -l -a output
	if test (count $output) -ge 5 && test "$output[5]" != 0 && string match -qr '^\d+$' -- "$output[5]"
		echo "$output[5]"
		return 0
	end

	# size is 0, or `ls -L` couldn't parse a plain size (char/block devices
	# show "major, minor" there instead of a size), or the path doesn't
	# exist at all. use `command test`, not the builtin: fish's builtin
	# `test -p`/`-S` misdetects /dev/stdin as the tail of an internal
	# pipeline (e.g. `cat file | fn`), always reporting false
	if command test -p "$file" -o -S "$file"
		echo -1
		return 0
	end

	# devices don't carry a meaningful size in `ls -l`, ask `stat` instead
	if command test -c "$file" -o -b "$file"
		set -l size
		if $__cap_stat_has_printf
			command stat -L --printf '%s' "$file" 2>/dev/null | read size
		else
			command stat -L -f %z "$file" 2>/dev/null | read size
		end
		if test $pipestatus[1] -eq 0 && string match -qr '^\d+$' -- "$size"
			echo "$size"
			return 0
		end
		echo -1
		return 0
	end

	if test (count $output) -ge 5
		echo "$output[5]"
		return 0
	end

	echo -2
	return 1
end

