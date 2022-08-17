function untagdir -d "untag cwd to shorten name: [ NAME | PATH ]"
	if [ (count $argv) -eq 1 ]
		set search $argv[1]
	else
		set search "$PWD"
	end
	for tagged_dir in $__tagged_dirs
		if [ "$__tagged_dirs_name_list[$tagged_dir]" = "$search" ] || [ "$__tagged_dirs_path_list[$tagged_dir]" = "$search" ]
			set --universal -e __tagged_dirs
			set --universal -e __tagged_dirs_name_list[$tagged_dir]
			set --universal -e __tagged_dirs_path_list[$tagged_dir]
			# reindex
			for tagged_dir in $__tagged_dirs_name_list
				set --universal __tagged_dirs $__tagged_dirs (count x $__tagged_dirs)
			end
			__sp_sync_tagdir_mc_hotlist
			return 0
		end
	end
	echo "No such tag name or path"
	return 1
end
