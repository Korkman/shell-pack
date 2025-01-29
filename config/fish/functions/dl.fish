function dl -d "Download a file, via https:// by default, use either curl or wget, ask to resume or overwrite if already present"
	# set defaults
	set -l preferred wget
	set -l force_preferred no
	set -l verbose no
	set -l silent no
	set -l to_stdout no
	set -l resume_dl ask
	
	if [ (count $argv) = 0 ]
		begin
			echo "Usage: dl [--curl|--wget] [-v|--verbose] [-s|--silent] [--resume|--overwrite] <url> [output_file]"
			echo "  Preferred backend is $preferred."
			if test "$resume_dl" = "yes"
				echo "  By default, downloads are resumed if already present."
				echo "  Does not apply when redirecting to stdout."
			end
		end >&2
		return 1
	end
	
	# interpret, filter dash prefixed args
	set -l args
	for arg in $argv
		switch $arg
			case '--curl'
				set preferred curl
				set force_preferred yes
			case '--wget'
				set preferred wget
				set force_preferred yes
			case '-v' '--verbose'
				set verbose yes
			case '-s' '--silent' '-q' '--quiet'
				set silent yes
			case '-c' '--continue' '--resume'
				set resume_dl yes
			case '-n' '--no-resume' '--new' '--restart' '--no-continue' '--overwrite'
				set resume_dl no
			case '*'
				set -a args "$arg"
		end
	end
	set argv $args
	
	if ! isatty 1
		set to_stdout yes
	end
	test "$to_stdout,$silent" = "yes,no" && echo "Redirection detected, writing to stdout" >&2
	
	# select backend
	set -l use_tool $preferred
	if ! type -q $preferred
		if test "$force_preferred" = "yes"
			echo "$preferred not available." >&2
			return 1
		end
		if type -q curl
			set use_tool curl
		else if type -q wget
			set use_tool wget
		else
			echo "Neither curl nor wget available." >&2
			return 1
		end
	end
	
	# process url
	set url $argv[1]
	
	# if no protocol given, assume https://
	if ! string match -q --regex '^[^:/]+://' -- "$url"
		set url "https://$url"
	end
	
	# process output_file
	set output_file $argv[2]
	
	# determine output_file so we can ask for resume and harmonize curl / wget naming behavior
	if test "$to_stdout" = "no"
		if test -z "$output_file"
			# copy url as output filename, remove query
			set output_file "$url"
			set output_file (string replace --regex '\?.*' '' -- "$output_file")
			if string match -qr '/$' -- "$output_file"
				# ends on a slash? remove it.
				set output_file (string replace -r '/$' '' -- "$output_file")
			end
			if string match -qr '.*://[^/]+$' -- "$output_file"
				# no slash after protocol = domain only, append .htm
				set output_file "$output_file.htm"
			end
			set output_file (basename "$output_file")
			set output_file (string unescape --style=url -- "$output_file")
			if test -z "$output_file"
				set output_file "download"
			end
			set output_file_guessed yes
		end
		if test -e "$output_file" && test "$resume_dl" = "ask"
			if isatty 0
				read -P "File exists: $output_file - (r)esume, (O)verwrite, (c)ancel? (r/O/c)" answer || set answer n
				switch (string lower -- "$answer")
					case 'r'
						echo "Resume file if possible ..." >&2
					case 'o' ''
						echo "Overwrite file ..." >&2
						rm "$output_file"
						set resume_dl no
					case '*'
						return 1
				end
			else
				# in non-interactive mode, assume no resume is desired
				set resume_dl no
			end
		end
	end
	
	
	if test "$use_tool" = "curl"
		test "$silent" = "yes" || echo "Download with curl ..." >&2
		set -l base_opt -L --max-redirs 10 --retry 3 -f
		set -l silent_opt
		set -l writeout_opt --write-out '%{url_effective}\n-> HTTP %{http_code} %{content_type}\n'
		set -l resume_opt -C -
		if test "$resume_dl" = "no" || test "$to_stdout" = "yes" 
			set -e resume_opt
		end
		if test "$to_stdout" = "yes"
			# later curl versions (Debian Buster and up) support the write-out
			# variable %{stderr} to switch output removing the argument for now to be compatible
			set -e writeout_opt
		end
		if test "$silent" = "yes"
			set silent_opt "-s"
			set -e writeout_opt
		end
		if test "$verbose" = "yes"
			if test "$to_stdout" = "yes" || test -n "$output_file"
				set -a base_opt -D /dev/stderr
			else
				set -a base_opt -D -
			end
		end
		
		if test -n "$output_file"
			curl $base_opt $silent_opt $writeout_opt $resume_opt -o "$output_file" "$url" || return 1
		else if test "$to_stdout" = "no"
			curl $base_opt $silent_opt $writeout_opt $resume_opt -O "$url" 1>&2 || return 1
		else
			curl $base_opt $silent_opt $writeout_opt $resume_opt "$url" || return 1
		end
		
		
	else if test "$use_tool" = "wget"
		test "$silent" = "yes" || echo "Download with wget ..." >&2
		set -l base_opt --max-redirect=10 --tries 3
		set -l silent_opt
		set -l show_prog_opt "--show-progress"
		set -l resume_opt -c
		if test "$resume_dl" = "no" || test "$to_stdout" = "yes" 
			set -e resume_opt
		end
		if test "$silent" = "yes"
			set silent_opt "-q"
			set -e show_prog_opt
		end
		if test "$verbose" = "yes"
			set -a base_opt --show-progress --server-response
		else
			set -a base_opt --no-verbose --show-progress
		end
		if test -n "$output_file"
			set final_opt -O "$output_file" "$url"
		else if test "$to_stdout" = "no"
			set final_opt "$url"
		else
			set final_opt -O - "$url"
		end
		wget $base_opt $silent_opt $resume_opt $final_opt || return 1
		
		
	else
		echo "Internal error" >&2
		return 1
	end
	
	# rename suggestion based on content if interactive and file was created
	if test -n "$output_file" && isatty 0 && test -e "$output_file" && type -q file
		set output_file (__sp_suggest_rename_file "$output_file")
	end
	
end
