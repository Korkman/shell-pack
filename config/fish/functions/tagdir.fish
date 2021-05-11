# directory tagging section
function tagdir -d "tag cwd to shorten name"
	if [ (count $argv) -eq 1 ]
		set tagged_dir "$PWD"
		set tagged_name "$argv[1]"
	else if [ (count $argv) -eq 2 ]
		set tagged_dir "$argv[1]"
		set tagged_name "$argv[2]"
	else
		echo "Usage: tagdir [ DIRECTORY ] NAME"
		return 1
	end
	
	#set tagged_dir (realpath "$tagged_dir")
	if [ ! -e "$tagged_dir" ]
		echo "Directory does not exist: $tagged_dir"
		return 2
	end
	
	if string match --quiet --regex '.*:.*' "$tagged_name"
		echo "Colons not allowed in tag names"
		return 3
	end
	__untagdirpath "$tagged_dir"
	
	# start count at 1
	set --universal __tagged_dirs $__tagged_dirs (count x $__tagged_dirs)
	set --universal __tagged_dirs_path_list $__tagged_dirs_path_list $tagged_dir
	set --universal __tagged_dirs_name_list $__tagged_dirs_name_list $tagged_name

	__sp_sync_tagdir_mc_hotlist
end
