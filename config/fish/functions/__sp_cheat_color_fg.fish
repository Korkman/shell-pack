function __sp_cheat_color_fg
	# picks black (30) or bright white (97) foreground for readability on the given rgb background
	set -l r $argv[1]
	set -l g $argv[2]
	set -l b $argv[3]
	set -l luma (math -s0 "0.299 * $r + 0.587 * $g + 0.114 * $b")
	if test $luma -gt 140
		echo 30
	else
		echo 97
	end
end
