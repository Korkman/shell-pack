function __sp_cheat_color_value
	set -l idx $argv[1]
	if ! string match -qr '^\d+$' -- "$idx" || test $idx -lt 0 || test $idx -gt 255
		echo "cheat --color: INDEX must be a number between 0 and 255" >&2
		return 1
	end

	set -l r
	set -l g
	set -l b
	if test $idx -lt 16
		set -l basic_r 0 128 0 128 0 128 0 192 128 255 0 255 0 255 0 255
		set -l basic_g 0 0 128 128 0 0 128 192 128 0 255 255 0 0 255 255
		set -l basic_b 0 0 0 0 128 128 128 192 128 0 0 0 255 255 255 255
		set r $basic_r[(math "$idx + 1")]
		set g $basic_g[(math "$idx + 1")]
		set b $basic_b[(math "$idx + 1")]
	else if test $idx -lt 232
		set -l levels 0 95 135 175 215 255
		set -l cube (math "$idx - 16")
		set -l red (math -s0 "floor($cube / 36)")
		set -l green (math -s0 "floor(($cube % 36) / 6)")
		set -l blue (math -s0 "$cube % 6")
		set r $levels[(math "$red + 1")]
		set g $levels[(math "$green + 1")]
		set b $levels[(math "$blue + 1")]
	else
		set r (math "8 + 10 * ($idx - 232)")
		set g $r
		set b $r
	end

	set -l fg (__sp_cheat_color_fg $r $g $b)
	printf "\e[48;5;%sm\e[%sm    \e[0m  " $idx $fg
	printf "index %d\n" $idx
	printf "  RGB array:  [%d, %d, %d]\n" $r $g $b
	printf "  CSS hex:    #%02x%02x%02x\n" $r $g $b
end
