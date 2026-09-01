function __sp_bytes_human_readable -a bytes -d \
	'Format a byte count as a human-readable string (B/KiB/MiB/GiB/TiB/PiB, base 1024)'
	if not string match -qr '^\d+$' -- "$bytes"
		echo "$bytes"
		return 1
	end

	set -l units B KiB MiB GiB TiB PiB
	set -l divisor 1
	set -l idx 1
	# math can't be used for comparisons, so scale divisor via test on integers
	while test $idx -lt (count $units)
		set -l next_divisor (math "$divisor * 1024")
		if test "$bytes" -lt "$next_divisor"
			break
		end
		set divisor $next_divisor
		set idx (math $idx + 1)
	end

	if test $idx -eq 1
		echo "$bytes $units[$idx]"
	else
		set -l value (math -s1 "$bytes / $divisor")
		echo (string replace -r '\.0$' '' -- $value)" $units[$idx]"
	end
end
