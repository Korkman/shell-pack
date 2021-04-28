function getdirpath --no-scope-shadowing -d "return tag path for tag: VARNAME TAG"
	if [ (count $argv) -ne 2 ]
		echo "Usage: getdirpath VARNAME TAG"
		return 2
	end
	set --local vname $argv[1]
	set --local search "$argv[2]"
	for tagged_dir in $__tagged_dirs
		if [ "$__tagged_dirs_name_list[$tagged_dir]" = "$search" ]
			set $vname "$__tagged_dirs_path_list[$tagged_dir]"
			return 0
		end
	end
	return 1
end
