function __sp_sync_tagdir_mc_hotlist -d \
	"Synchronizes shell-pack tagged dirs into the mc hotlist"

	set hotlistFile "$HOME/.config/mc/hotlist"
	set spGroup "shell-pack"

	# logic
	#
	# if hotlistFile is not present, create it
	# if GROUP "shell-pack" is not present, insert
	# GROUP "shell-pack"
	#   # anything user created in this group will be overwritten without notice (sorry)
	#   GROUP "subgroup"
	#     # there won't be any subgroups, this is just to illustrate the looks of "ENDGROUP"
	#   ENDGROUP
	#   ENTRY "downloads" URL "/home/pbeck/Downloads" # this is how the actual hotlist entries look
	# ENDGROUP # this is not indented, important for the parser
	#
	# anything outside this group will be preserved

	if test ! -e "$hotlistFile"
		touch "$hotlistFile"
	end

	# read whole file into array (we don't expect it to grow super large)
	cat "$hotlistFile" | while read -a line; set -a hotlistLines "$line"; end

	#echo "cnt lines: "(count $hotlistLines)

	set spGroupFound no
	set parsePos 1
	set parseMax (count $hotlistLines)
	for i in (seq $parsePos $parseMax)
		set line "$hotlistLines[$i]"
		set -a newHotlistLines "$line"
		#echo "$line"
		#echo "GROUP \"$spGroup\""
		if test "$line" = "GROUP \"$spGroup\""
			set spGroupFound yes
			#echo "found"
			break
		end
	end
	set parsePos $i

	if test "$spGroupFound" = "no"
		set -a newHotlistLines "GROUP \"$spGroup\""
	end

	for tagged_dir in $__tagged_dirs
		set -a newHotlistLines "  ENTRY \"$__tagged_dirs_name_list[$tagged_dir]\" URL \"$__tagged_dirs_path_list[$tagged_dir]\""
	end

	if test "$spGroupFound" = "no"
		set -a newHotlistLines "ENDGROUP"
	end

	# continue reading without copying until ENDGROUP
	for i in (seq $parsePos $parseMax)
		set line "$hotlistLines[$i]"
		if test "$line" = "ENDGROUP"
			break
		end
	end
	set parsePos $i

	# continue reading and copying
	for i in (seq $parsePos $parseMax)
		set line "$hotlistLines[$i]"
		set -a newHotlistLines "$line"
	end

	# write out new file
	echo -n "" > "$hotlistFile.new"
	for line in $newHotlistLines
		echo "$line" >> "$hotlistFile.new"
	end

	# delete old backup (if present), move current to backup, move new to current
	# NOTE: mc uses the .bak file as well!
	rm -f "$hotlistFile.bak"
	mv "$hotlistFile" "$hotlistFile.bak"
	mv "$hotlistFile.new" "$hotlistFile"
end
