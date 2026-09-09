function __sp_cheat_blocks_per_row
	# argv: block_width gap max_blocks block_count -> how many blocks fit on one terminal row
	set -l block_width $argv[1]
	set -l gap $argv[2]
	set -l max_blocks (math "min($argv[3], $argv[4])")
	set -l cols $COLUMNS
	if test -z "$cols"
		set cols 80
	end
	for n in (seq $max_blocks -1 1)
		if test (math "$n * $block_width + ($n - 1) * $gap") -le $cols
			echo $n
			return
		end
	end
	echo 1
end
