function __sp_cheat_glyphs
	set -l pl_a1 (set_color 711)""(set_color -b 711)" "(set_color normal; set_color 711)""(set_color normal)
	set -l pl_a2 (set_color 171)""(set_color -b 171)" "(set_color normal; set_color 171)""(set_color normal)
	set -l pl_a3 (set_color yellow)""(set_color -b yellow)" "(set_color normal; set_color yellow)""(set_color normal)
	set -l policeline (set_color ff0)""(set_color normal)
	set -l style_b (echo -e '\e[1mBold\e[0m')
	set -l style_i (echo -e '\e[3mItalic\e[0m')
	set -l style_u (echo -e '\e[4mUnderline\e[0m')
	set -l style_s (echo -e '\e[9mStrike\e[0m')
	echo -n "Terminal glyphs and capabilities test:

   ┌──────────────────────────┐
  │ Powerline Solid Arrow    └── This line must appear solid! (mc)
  │ Powerline Hollow Arrow   
  │ Read-only lock          🠴 UTF8 7.0 'Finger-Post' Arrows 🠶
  │ Bookmark                
  │ Debian Swirl Logo       Batteries at 10, 50, 100%, charging: 󰢜 󰢝 󰂅
  │ Exit Error                                     not charging: 󰁺 󰁾 󰁹
 󰋞 │ Home                     
  │ Hourglass End           Styles: $style_i, $style_s, $style_b and $style_u
  │ Exit OK                  
  │ Walking man             Powerlines: $pl_a1 $pl_a2 $pl_a3
 ↓ │ Arrow Down (mc)                     Disrupted? Adjust font size.
  │ Calendar                 
 ✕ │ Close X (mc)            Policeline: $policeline 
───┘   
 __ Glyphs must not be cut off - some symbols may be as wide as these two
    underscores! If they don't, your font is monospace, which is wrong.

Are these color gradients fine?
"
	# red
	for i in 4 7 a c e
		set_color -b "$i""$i"0000
		echo -n "  "
	end
	for j in 3 7 a c e f
		set_color -b ff"$j""$j""$j""$j"
		echo -n "  "
	end
	set_color normal
	#echo
	# yellow
	for i in 4 7 a c e
		set_color -b "$i""$i""$i""$i"00
		echo -n "  "
	end
	for j in 3 7 a c e f
		set_color -b ffff"$j""$j"
		echo -n "  "
	end
	set_color normal
	#echo
	# green
	for i in 4 7 a c e
		set_color -b 00"$i""$i"00
		echo -n "  "
	end
	for j in 3 7 a c e f
		set_color -b "$j""$j"ff"$j""$j"
		echo -n "  "
	end
	set_color normal
	echo
	# cyan
	for i in 4 7 a c e
		set_color -b 00"$i""$i""$i""$i"
		echo -n "  "
	end
	for j in 3 7 a c e f
		set_color -b "$j""$j"ffff
		echo -n "  "
	end
	set_color normal
	#echo
	# blue
	for i in 4 7 a c e
		set_color -b 0000"$i""$i"
		echo -n "  "
	end
	for j in 3 7 a c e f
		set_color -b "$j""$j""$j""$j"ff
		echo -n "  "
	end
	set_color normal
	#echo
	# magenta
	for i in 4 7 a c e
		set_color -b "$i""$i"00"$i""$i"
		echo -n "  "
	end
	for j in 3 7 a c e f
		set_color -b ff"$j""$j"ff
		echo -n "  "
	end
	set_color normal
	echo
end
