function lsdirtags -d "list all directory tags"
	for tagged_dir in $__tagged_dirs
		echo "$__tagged_dirs_name_list[$tagged_dir]"':'"$__tagged_dirs_path_list[$tagged_dir]"
	end
end
