# directory tagging section
function tagdir -d "tag cwd to shorten name"
	argparse 'h/help' -- $argv
	
	set -l tagged_dir
	set -l tagged_name
	if set -q _flag_help || [ (count $argv) -gt 2 ]
		echo "Usage: tagdir [ DIRECTORY ] [ NAME ]"
		return 1
	else if [ (count $argv) -eq 0 ]
		# no arguments: use fish prompt_pwd shortener to generate a tag
		set tagged_dir "$PWD"
		begin
			set -lx fish_prompt_pwd_dir_length 1
			set tagged_name (prompt_pwd)
			# prophylactic: if fish ever comes up with color codes in prompt_pwd, strip them here
			set tagged_name (string replace -ra '\e\[[^m]*m' '' "$tagged_name" | string replace -ra '[^[:print:]]' '')
			# colons are not allowed, strip them as well
			set tagged_name (string replace --all -- ':' '-' "$tagged_name")
		end
	else if [ (count $argv) -eq 1 ]
		# one argument: is the tag to be used for the current dir
		set tagged_dir "$PWD"
		set tagged_name "$argv[1]"
	else if [ (count $argv) -eq 2 ]
		# two arguments: is directory first, then tag to be used
		set tagged_dir "$argv[1]"
		set tagged_name "$argv[2]"
	else
		echo "this can't happen."
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
