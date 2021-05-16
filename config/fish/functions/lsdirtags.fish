function lsdirtags -d "list all directory tags"
	argparse -n lsdirtags 'c/color=' -- $argv
	if set -q _flag_color && test "$_flag_color" = "never"
		set -e _flag_color
	else
		set _flag_color 'always'
	end
	
	if set -q _flag_color
		for tagged_dir in $__tagged_dirs
			echo (set_color bryellow)"$__tagged_dirs_name_list[$tagged_dir]"(set_color normal)':'"$__tagged_dirs_path_list[$tagged_dir]"
		end
	else
		for tagged_dir in $__tagged_dirs
			echo "$__tagged_dirs_name_list[$tagged_dir]"':'"$__tagged_dirs_path_list[$tagged_dir]"
		end
	end
end
