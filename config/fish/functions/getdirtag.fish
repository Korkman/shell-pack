function getdirtag --no-scope-shadowing -d "return tag for current directory: VARNAME"
	if [ (count $argv) -ne 1 ]
		echo "Usage: getdirtag VARNAME - variable to write result to"
		return 2
	end
	set --local vname $argv[1]
	set --local search "$PWD"
	for tagged_dir in $__tagged_dirs
		if [ "$__tagged_dirs_path_list[$tagged_dir]" = "$search" ]
			set $vname "$__tagged_dirs_name_list[$tagged_dir]"
			return 0
		end
	end
	return 1
end
