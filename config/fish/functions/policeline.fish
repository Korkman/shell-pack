function policeline -d "Output a warning, clear and loud" -a text
	set -l text_budget (math (string length -- $text) + 4 )
	set -l left_budget (math -s0 \($COLUMNS - $text_budget\) / 2 - 2)
	set -l right_budget (math $COLUMNS - $left_budget - $text_budget - 2)
	set -l text (string upper -- $text)
	
	__spt policeline_fg
	set -l alternator 0
	while [ $left_budget -gt 0 ]
		set left_budget (math $left_budget - 1)
		if [ $alternator -eq 0 ]
			echo -n (__spt white_black_forward_block)
			set alternator 1
		else
			echo -n (__spt black_white_forward_block)
			set alternator 0
		end
	end
	
	if [ $alternator -eq 1 ]
		set right_budget (math $right_budget - 1)
		echo -n (__spt black_white_forward_block)
	end
	
	__spt policeline_text
	echo -n "   $text   "
	
	__spt policeline_fg
	set -l alternator 0
	while [ $right_budget -gt 0 ]
		set right_budget (math $right_budget - 1)
		if [ $alternator -eq 0 ]
			echo -n (__spt white_black_forward_block)
			set alternator 1
		else
			echo -n (__spt black_white_forward_block)
			set alternator 0
		end
	end
	set_color normal
	echo
end
