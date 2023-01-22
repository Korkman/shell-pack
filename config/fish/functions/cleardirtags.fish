function cleardirtags -d "untag all directories"
	set --universal -e __tagged_dirs
	set --universal -e __tagged_dirs_path_list
	set --universal -e __tagged_dirs_name_list
	return 0
end
