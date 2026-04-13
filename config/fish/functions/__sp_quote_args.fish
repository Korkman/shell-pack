function __sp_quote_args -d \
	"fzf (and POSIX sh?) compatible argument escaping - fzf does not support \\'"
	set -l sep ''
	for opt in $argv
		# quote argument only when necessary
		if test $opt = '' || string match -q --regex -- '[\n\\"\' \(\)~#]' $opt
			echo -n $sep'"'
			echo -n -- $opt | string replace -a -- "\\" "\\\\" | string replace -a -- '"' '\\"'
			echo -n '"'
		else
			echo -n $sep
			echo -n -- $opt
		end
		
		set sep ' '
	end
end
