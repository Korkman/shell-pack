function __sp_fzf_header -S
	set -l current_columns 0
	set fzf_header
	set first_line yes
	while read -l line
		set -l line_length (string length -- "$line")
		set current_columns (math "$current_columns + $line_length + 2")
		if test $current_columns -gt $COLUMNS
			if test "$first_line" = "no"
				echo
			end
			set current_columns $line_length
		end
		set line (string replace --all --regex -- '([^ ]+:)' (set_color --bold white)"\$1"(set_color normal) "$line")
		echo -n "$line "
		set first_line no
	end | read -z fzf_header
end
