function __untagdirpath -d "untag cwd to shorten name: [ PATH ]"
	set search $argv[1]
	for tagged_dir in $__tagged_dirs
		if [ "$__tagged_dirs_path_list[$tagged_dir]" = "$search" ]
			set --universal -e __tagged_dirs
			set --universal -e __tagged_dirs_name_list[$tagged_dir]
			set --universal -e __tagged_dirs_path_list[$tagged_dir]
			# reindex
			for tagged_dir in $__tagged_dirs_name_list
				set --universal __tagged_dirs $__tagged_dirs (count x $__tagged_dirs)
			end
			return 0
		end
	end
	return 0
end
