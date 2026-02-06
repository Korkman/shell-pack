function __sp_column_t -d \
	'A drop-in replacement for column -t if column is not available'

	# If column is available, use it directly
	if command -q column
		column -t $argv
		return
	end

	# Pure-fish fallback: read all lines, compute max widths, then print aligned
	set -l lines
	set -l max_cols 0

	# Read all input lines
	while read -l line
		set -a lines $line
	end

	# Nothing to do if no input
	if test (count $lines) -eq 0
		return
	end

	# Split each line into fields and track max column count
	set -l all_fields
	for line in $lines
		set -l fields (string match -ra '\S+' -- $line)
		set -l n (count $fields)
		if test $n -gt $max_cols
			set max_cols $n
		end
		set -a all_fields (string join \t -- $fields)
	end

	# Compute max width for each column
	set -l widths
	for i in (seq 1 $max_cols)
		set -a widths 0
	end

	for entry in $all_fields
		set -l fields (string split \t -- $entry)
		set -l n (count $fields)
		for i in (seq 1 $n)
			set -l len (string length -- $fields[$i])
			if test $len -gt $widths[$i]
				set widths[$i] $len
			end
		end
	end

	# Print each line with columns padded to max widths
	for entry in $all_fields
		set -l fields (string split \t -- $entry)
		set -l n (count $fields)
		set -l out ''
		for i in (seq 1 $n)
			if test $i -lt $n
				set -l padded (printf "%-"$widths[$i]"s" $fields[$i])
				set out "$out$padded  "
			else
				# Last column: no trailing padding
				set out "$out$fields[$i]"
			end
		end
		echo $out
	end
end