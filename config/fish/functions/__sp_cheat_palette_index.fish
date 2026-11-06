function __sp_cheat_palette_index -d "print the 256-color index closest to an RGB value and its squared distance" -a r -a g -a b
	set -l levels 0 95 135 175 215 255
	set -l pr 0 128 0 128 0 128 0 192 128 255 0 255 0 255 0 255
	set -l pg 0 0 128 128 0 0 128 192 128 0 255 255 0 0 255 255
	set -l pb 0 0 0 0 128 128 128 192 128 0 0 0 255 255 255 255
	for red in $levels
		for green in $levels
			for blue in $levels
				set -a pr $red
				set -a pg $green
				set -a pb $blue
			end
		end
	end
	for v in (seq 8 10 238)
		set -a pr $v
		set -a pg $v
		set -a pb $v
	end

	set -l best 0
	set -l best_dist -1
	for i in (seq 1 256)
		set -l d (math "($pr[$i] - $r)^2 + ($pg[$i] - $g)^2 + ($pb[$i] - $b)^2")
		if test $best_dist -lt 0; or test $d -lt $best_dist
			set best_dist $d
			set best (math "$i - 1")
		end
	end
	printf "%d\n%d\n" $best $best_dist
end
