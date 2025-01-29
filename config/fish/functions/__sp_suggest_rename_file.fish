function __sp_suggest_rename_file -d \
	'Suggest renaming the file to match extension with content'
	set output_file "$argv[1]"
	
	test -n "$output_file" || begin
		echo "Usage: __sp_suggest_rename_file FILE"
		echo "  Suggest renaming the file to match extension with content"
		return 1
	end >&2
	
	if ! type -q file
		return
	end
	
	set mime_type (file -b --mime-type "$output_file")
	# --extension is supported from Debian Stretch and up, but often returns ??? for common mime types :-(
	set valid_extensions (file -b --extension "$output_file" 2>/dev/null) || set valid_extensions '???'
	if test "$valid_extensions" = "???"
		switch "$mime_type"
			case 'application/zip'
				set valid_extensions "zip"
			case 'text/html'
				set valid_extensions "htm/html"
			case 'text/plain'
				set valid_extensions "txt/text/md"
			case '*'
				set valid_extensions "???"
		end
	end
	# pick first extension as automatic
	set auto_extension (string replace --regex '/.*' '' -- "$valid_extensions")
	
	# TODO: search current ending in list of valid endings returned by file
	if test "$auto_extension" != "???" && ! string match -q --regex "\\.$auto_extension\$" -- "$output_file"
		set new_output_dir (dirname (realpath "$output_file"))
		set new_output_file $new_output_dir"/"(string replace --regex '(\.tar){0,1}\.[^\.]+$' '' -- (basename "$output_file"))".$auto_extension"
		
		echo "Filename does not match content type: $mime_type -> .$auto_extension" >&2
		# ask to rename the file
		echo "Rename to $new_output_file? (Y/n)" >&2
		read -P "" answer || set answer "n"
		if test (string lower -- "$answer") = "y" || test "$answer" = ""
			if test -e "$new_output_file"
				echo "File exists. Overwrite? (Y/n)" >&2
				read -P "" answer || set answer "n"
			end
			if test (string lower -- "$answer") = "y" || test "$answer" = ""
				mv "$output_file" "$new_output_file"
				echo "$new_output_file"
			end
		end
	end
	echo "$output_file"
end