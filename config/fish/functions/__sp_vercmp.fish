function __sp_vercmp \
	--description "Compare versions"

	# New implementation for version comparisons
	# - Runs of digits are compared as whole numbers, so "1.10" > "1.1".
	# - If one version is a prefix of the other, the longer one (with the
	#   extra trailing characters) is considered greater, e.g. "1.1a" > "1.1"
	#   and "1.1b" > "1.1a".
	#
	# Prints "-1" and returns 1 if the first version is smaller
	# Prints "1" and returns 2 if the first version is greater
	# Prints and returns 0 if both are equal

	if not set -q argv[2]
		echo "Expected two arguments" >&2
		return 2
	end

	# Tokenize each version into runs of consecutive digits / non-digits.
	set -l versions $argv[1] $argv[2]
	set -l tokens1
	set -l tokens2
	for idx in 1 2
		set -l tokens
		set -l current ""
		set -l current_is_digit ""
		for c in (string split "" -- $versions[$idx])
			set -l is_digit 0
			string match -qr '^[0-9]$' -- $c; and set is_digit 1
			if test -z "$current"
				set current $c
				set current_is_digit $is_digit
			else if test "$is_digit" = "$current_is_digit"
				set current "$current$c"
			else
				set tokens $tokens $current
				set current $c
				set current_is_digit $is_digit
			end
		end
		if test -n "$current"
			set tokens $tokens $current
		end
		if test $idx -eq 1
			set tokens1 $tokens
		else
			set tokens2 $tokens
		end
	end

	while true
		if not set -q tokens1[1]; and not set -q tokens2[1]
			echo 0
			return 0
		else if not set -q tokens1[1]
			# First ran out of tokens - second has extra trailing characters.
			echo -1
			return 1
		else if not set -q tokens2[1]
			echo 1
			return 2
		end

		set -l t1 $tokens1[1]
		set -l t2 $tokens2[1]
		set -e tokens1[1]
		set -e tokens2[1]

		if test "$t1" = "$t2"
			continue
		end

		set -l t1_digit 0
		set -l t2_digit 0
		string match -qr '^[0-9]+$' -- $t1; and set t1_digit 1
		string match -qr '^[0-9]+$' -- $t2; and set t2_digit 1

		if test $t1_digit -eq 1 -a $t2_digit -eq 1
			if test "$t1" -eq "$t2"
				continue
			else if test "$t1" -lt "$t2"
				echo -1
				return 1
			else
				echo 1
				return 2
			end
		else
			# Compare byte by byte; whichever token is a prefix of the other
			# but shorter is considered smaller.
			set -l c1 (string split "" -- $t1)
			set -l c2 (string split "" -- $t2)
			set -l n (count $c1)
			set -l m (count $c2)
			set -l i 1
			while test $i -le $n -a $i -le $m
				if test "$c1[$i]" != "$c2[$i]"
					set -l a (printf '%d' "'$c1[$i]")
					set -l b (printf '%d' "'$c2[$i]")
					if test $a -lt $b
						echo -1
						return 1
					else
						echo 1
						return 2
					end
				end
				set i (math $i + 1)
			end
			if test $n -lt $m
				echo -1
				return 1
			else
				echo 1
				return 2
			end
		end
	end
end
