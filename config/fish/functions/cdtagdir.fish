function cdtagdir -d "cd into tagged dir: NAME"
	if [ (count $argv) -eq 1 ]
		getdirpath target $argv[1]
		cd "$target"
	else if [ (count $argv) -eq 0 ]
		if [ "$matched_tagged_dir_name" = "" ]
			echo "Not inside tagged directory"
			echo
			echo "tag directories with 'tagdir'"
			echo "untag with 'untagdir'"
			echo "list tagged directories with 'lsdirtags'"
		else
			cdtagdir "$matched_tagged_dir_name"
		end
	else
		echo "Usage: d NAME"
		echo "cd into tagged dir NAME"
		echo
		echo "Available tagged directories:"
		lsdirtags
	end
end
