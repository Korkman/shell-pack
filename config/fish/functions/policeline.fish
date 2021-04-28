function policeline -d "Output a warning, clear and loud" -a text
	__update_glyphs
	set -l text_budget (math (string length -- $text) + 6 )
	set -l left_budget (math -s0 \($COLUMNS - $text_budget\) / 2 - 2)
	set -l right_budget (math $COLUMNS - $left_budget - $text_budget - 2)
	set -l text (string upper -- $text)
	
	set_color ff0
	set -l alternator 0
	while [ $left_budget -gt 0 ]
		set left_budget (math $left_budget - 2)
		if [ $alternator -eq 0 ]
			echo -n $white_black_forward_block
			set alternator 1
		else
			echo -n $black_white_forward_block
			set alternator 0
		end
	end
	
	if [ $alternator -eq 1 ]
		set right_budget (math $right_budget - 2)
		echo -n $black_white_forward_block
	end
	
	set_color fff
	echo -n "   $text   "
	
	set_color ff0
	set -l alternator 0
	while [ $right_budget -gt 0 ]
		set right_budget (math $right_budget - 2)
		if [ $alternator -eq 0 ]
			echo -n $white_black_forward_block
			set alternator 1
		else
			echo -n $black_white_forward_block
			set alternator 0
		end
	end
	set_color normal
	echo
end
