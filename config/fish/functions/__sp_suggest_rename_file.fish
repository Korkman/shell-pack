function __sp_suggest_rename_file -d \
	'Suggest renaming the file to match extension with content'
	set output_file "$argv[1]"
	
	test -n "$output_file" || begin
		echo "Usage: __sp_suggest_rename_file FILE"
		echo "  Suggest renaming the file to match extension with content"
		return 1
	end >&2
	
	if ! type -q file
		echo "$output_file"
		return
	end
	if ! test -f "$output_file"
		echo "File does not exist: $output_file" >&2
		echo "$output_file"
		return
	end
	
	set mime_type (file -b --mime-type "$output_file")
	if test "$status" -ne 0
		echo "Execution of 'file' failed" >&2
		echo "$output_file"
		return
	end
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
	set valid_extensions_list (string split '/' -- "$valid_extensions")
	# more hotfixes for file -b --extension
	set -l keep_tar no
	if contains -- "bz2" $valid_extensions_list
		set -a valid_extensions_list "tb2" "tbz" "tbz2" "tz2"
		set keep_tar yes
	else if contains -- "gz" $valid_extensions_list
		set -a valid_extensions_list "taz" "tgz"
		set keep_tar yes
	else if contains -- "lz" $valid_extensions_list
		set keep_tar yes
	else if contains -- "lzma" $valid_extensions_list
		set -a valid_extensions_list "tlz"
		set keep_tar yes
	else if contains -- "lzo" $valid_extensions_list
		set keep_tar yes
	else if contains -- "xz" $valid_extensions_list
		set -a valid_extensions_list "txz"
		set keep_tar yes
	else if contains -- "Z" $valid_extensions_list
		set -a valid_extensions_list "tZ" "taZ"
		set keep_tar yes
	else if contains -- "zst" $valid_extensions_list
		set -a valid_extensions_list "tzst"
		set keep_tar yes
	end
	
	# pick first extension as automatic
	set auto_extension "$valid_extensions_list[1]"
	
	# search current ending in list of valid endings returned by file
	set output_file_ext (string replace --regex '.*\.' '' -- "$output_file")
	if test -z "$output_file_ext"
		set output_file_ext "???"
	end
	
	if test "$auto_extension" != "???" && ! contains -- "$output_file_ext" $valid_extensions_list
		# if output_file is a tar file, keep the tar extension
		if test "$keep_tar" = "yes" && string match -qir '\.tar(\.|$)' -- "$output_file"
			set auto_extension "tar.$auto_extension"
		end
		
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
				return
			end
		end
	end
	echo "$output_file"
end