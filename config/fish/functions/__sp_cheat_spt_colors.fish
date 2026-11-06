function __sp_cheat_spt_colors
	# Parse the color section of __spt (everything before its glyph section)
	# into "COLOR|NAME" pairs, in source order.
	set -l pairs
	set -l case_names
	for line in (functions __spt | string trim)
		if string match -q -- '*# glyphs*' $line
			break
		end

		set -l names_part (string match -rg -- '^case (.+)$' $line)
		if test -n "$names_part"
			set case_names (string split ' ' -- $names_part)
			continue
		end

		set -l color (string match -rg -- '^(?:\$scolor|echo -n) (.+)$' $line)
		if test -z "$color"
			continue
		end
		set color (string replace -a '"' '' -- $color)
		for name in $case_names
			set pairs $pairs "$color|$name"
		end
	end

	set -l colors
	for pair in $pairs
		set -l color (string split -m1 '|' -- $pair)[1]
		contains -- $color $colors; or set -a colors $color
	end

	echo "Colors defined in __spt, grouped by color:"
	echo

	for color in $colors
		set -l names
		for pair in $pairs
			set -l parts (string split -m1 '|' -- $pair)
			if test "$parts[1]" = "$color"
				contains -- $parts[2] $names; or set -a names $parts[2]
			end
		end

		# plain colors are shown as a background swatch, flagged ones (--underline, --dim, ...) as styled text
		if string match -q -- '--*' $color
			set_color (string split ' ' -- $color)
			printf "  Aa  "
		else
			set_color -b $color
			printf "      "
		end
		set_color normal
		printf "  %-22s" $color

		# named colors use the xterm default palette, the terminal theme may show other values
		set -l value (string split ' ' -- $color)[-1]
		set -l hex
		switch $value
			case black
				set hex 000000
			case red
				set hex 800000
			case green
				set hex 008000
			case brown yellow
				set hex 808000
			case blue
				set hex 000080
			case magenta purple
				set hex 800080
			case cyan
				set hex 008080
			case white
				set hex c0c0c0
			case brblack
				set hex 808080
			case brred
				set hex ff0000
			case brgreen
				set hex 00ff00
			case bryellow brbrown
				set hex ffff00
			case brblue
				set hex 0000ff
			case brmagenta brpurple
				set hex ff00ff
			case brcyan
				set hex 00ffff
			case brwhite
				set hex ffffff
			case '*'
				set -l lower (string lower -- $value)
				if string match -qr '^[0-9a-f]{3}$' -- $lower
					set -l c (string split '' -- $lower)
					set hex $c[1]$c[1]$c[2]$c[2]$c[3]$c[3]
				else if string match -qr '^[0-9a-f]{6}$' -- $lower
					set hex $lower
				end
		end

		set -l hex_txt ""
		set -l rgb_txt ""
		set -l index_txt ""
		if test -n "$hex"
			set -l r (math "0x"(string sub -s 1 -l 2 -- $hex))
			set -l g (math "0x"(string sub -s 3 -l 2 -- $hex))
			set -l b (math "0x"(string sub -s 5 -l 2 -- $hex))
			set -l match (__sp_cheat_palette_index $r $g $b)
			set hex_txt "#$hex"
			set rgb_txt (printf "rgb(%d, %d, %d)" $r $g $b)
			set index_txt "index $match[1]"
			if test $match[2] -ne 0
				set index_txt "$index_txt (nearest)"
			end
		end
		printf "%-9s  %-18s  %s\n" $hex_txt $rgb_txt $index_txt
		printf "    %s\n\n" (string join ", " -- $names)
	end
end
