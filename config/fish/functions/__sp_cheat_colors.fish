function __sp_cheat_colors
	begin
		echo "256-color terminal palette (index shown on each swatch)"
		echo
		echo "0-15: the 16 basic ANSI colors (terminal themes apply)"
		echo
		set -l basic_r 0 128 0 128 0 128 0 192 128 255 0 255 0 255 0 255
		set -l basic_g 0 0 128 128 0 0 128 192 128 0 255 255 0 0 255 255
		set -l basic_b 0 0 0 0 128 128 128 192 128 0 0 0 255 255 255 255
		for i in (seq 0 15)
			set -l fg (__sp_cheat_color_fg $basic_r[(math "$i + 1")] $basic_g[(math "$i + 1")] $basic_b[(math "$i + 1")])
			printf "\e[48;5;%sm\e[%sm%4d\e[0m" $i $fg $i
			if test (math "($i + 1) % 8") -eq 0
				echo
			end
		end
		echo

		echo "16-231: 6x6x6 RGB color cubes (terminal themes usually don't apply)"
		echo
		set -l levels 0 95 135 175 215 255
		set -l cube_per_row (__sp_cheat_blocks_per_row 24 3 3 6)
		for group_start in (seq 0 $cube_per_row 5)
			set -l group_end (math "min($group_start + $cube_per_row - 1, 5)")
			set -l reds (seq $group_start $group_end)
			for green in (seq 0 5)
				for red in $reds
					for blue in (seq 0 5)
						set -l i (math "16 + $red * 36 + $green * 6 + $blue")
						set -l fg (__sp_cheat_color_fg $levels[(math "$red + 1")] $levels[(math "$green + 1")] $levels[(math "$blue + 1")])
						printf "\e[48;5;%sm\e[%sm%4d\e[0m" $i $fg $i
					end
					if test $red != $reds[-1]
						printf "   "
					end
				end
				echo
			end
			echo
		end

		echo "232-255: grayscale ramp, split into blocks of 6"
		echo
		set -l gray_per_row (__sp_cheat_blocks_per_row 24 3 3 2)
		for group_start in (seq 0 $gray_per_row 1)
			set -l group_end (math "min($group_start + $gray_per_row - 1, 1)")
			set -l blocks (seq $group_start $group_end)
			for row in 0 1
				for block in $blocks
					set -l base (math "232 + $block * 12 + $row * 6")
					for i in (seq $base (math "$base + 5"))
						set -l gray (math "8 + 10 * ($i - 232)")
						set -l fg (__sp_cheat_color_fg $gray $gray $gray)
						printf "\e[48;5;%sm\e[%sm%4d\e[0m" $i $fg $i
					end
					if test $block != $blocks[-1]
						printf "   "
					end
				end
				echo
			end
			echo
		end
	end

	while true
		read -l -P "Enter a color index for details (q to quit): " answer
		if test -z "$answer" || [ "$answer" = "q" ]
			return
		end
		if string match -qr '^\d+$' -- "$answer" && test $answer -ge 0 && test $answer -le 255
			__sp_cheat_color_value $answer
		else
			echo "Please enter a number 0-255, or 'q' to quit" >&2
		end
	end
end
