function dl -d \
"Download a file, via https:// by default, using either curl or wget 1.x. 
Will ask to resume or overwrite if already present. Pipe friendly."
	# set defaults
	set -l preferred wget
	set -l force_preferred no
	set -l verbose no
	set -l silent no
	set -l to_stdout no
	set -l resume_dl ask
	set -l retry_count 3
	
	set -l cache_pass_args
	set -l cache_key_args
	set -l cache_allow_stale no
	
	if test (count $argv) = 0 || test "$argv[1]" = '--help'
		echo "Usage: dl [--cache=EXPIRY] [--curl|--wget] [-v|--verbose] [-s|--silent] [--resume|--overwrite] [--retry=N] <url> [output_file]"
		echo
		echo -e (functions -vD (status current-function))[5]
		echo
		echo "Preferred backend is $preferred."
		if test "$resume_dl" = "yes"
			echo "  By default, downloads are resumed if already present."
			echo "  Does not apply when redirecting to stdout."
		end
		return 1
	end >&2
	
	# interpret, filter dash prefixed args
	set -l args
	for arg in $argv
		switch $arg
			case '--cache=*'
				set cache_expiry (string replace -r '^--[^=]+=?' '' -- "$arg")
			case '--cache-allow-stale'
				set cache_allow_stale yes
			case '--curl'
				set preferred curl
				set force_preferred yes
				set -a cache_pass_args '--curl'
				set -a cache_key_args '--curl'
			case '--wget'
				set preferred wget
				set force_preferred yes
				set -a cache_pass_args '--wget'
				set -a cache_key_args '--wget'
			case '-v' '--verbose'
				set verbose yes
				set -a cache_pass_args '-v'
			case '-s' '--silent' '-q' '--quiet'
				set silent yes
				set -a cache_pass_args '-s'
			case '-c' '--continue' '--resume'
				set resume_dl yes
				# silently ignored for --cache
			case '-n' '--no-resume' '--new' '--restart' '--no-continue' '--overwrite'
				set resume_dl no
				# silently ignored for --cache
			case '--retry=*' '--tries=*'
				set retry_count (string replace -r '^--[^=]+=?' '' -- "$arg")
				set -a cache_pass_args "$arg"
			case '*'
				set -a args "$arg"
				set -a cache_pass_args "$arg"
				set -a cache_key_args "$arg"
		end
	end
	set argv $args
	set url $argv[1]
	set output_file $argv[2]

	if test -n "$cache_expiry"
		set -l cache_key (string join0 -- $cache_key_args | __sp_getmd5)
		__sp_blob_cache --status $cache_key
		set -l cache_status $status
		if test $cache_status -ne 0
			set -l tmpfile (__sp_blob_cache --get-tmpfile) || return
			dl $cache_pass_args > $tmpfile
			set -l dl_status $status
			if test $dl_status -eq 0
				__sp_blob_cache --set --move-file=$tmpfile $cache_key $cache_expiry
			else
				rm $tmpfile
				if ! test $cache_allow_stale = yes || ! test $cache_status -eq 20
					# cache is unavailable or stale and stale was not allowed
					return 1
				end
				test "$silent" = "yes" || echo "Fetching from cache (stale!) ..." >&2
			end
		else
			test "$silent" = "yes" || echo "Fetching from cache ..." >&2
		end
		
		if test -n "$output_file"
			__sp_blob_cache --allow-stale --get $cache_key > $output_file
		else
			__sp_blob_cache --allow-stale --get $cache_key
		end
		return 0
	end
	
	if ! isatty 1
		set to_stdout yes
	end
	test "$to_stdout,$silent" = "yes,no" && echo "Redirection detected, writing to stdout" >&2
	
	type -q curl
	and set -l curl_available yes
	or set -l curl_available no
	
	# this function is not compatible with wget2. making it work is non-trivial.
	# TODO: implement wget2 compatibility
	type -q wget && ! wget --version | string match -q "GNU Wget2*"
	and set -l wget_available yes
	or set -l wget_available no
	
	# select backend
	set -l use_tool $preferred
	set -l test_var $preferred"_available"
	if test $$test_var = no
		if test "$force_preferred" = "yes"
			echo "$preferred not available." >&2
			return 1
		end
		if test $curl_available = yes
			set use_tool curl
		else if test $wget_available = yes
			set use_tool wget
		else
			echo "Neither curl nor wget 1.x available." >&2
			return 1
		end
	end
	
	# if no protocol given, assume https://
	if ! string match -q --regex '^[^:/]+://' -- "$url"
		set url "https://$url"
	end
	
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
		set -l base_opt -L --max-redirs 10 --retry $retry_count --globoff -f
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
			curl $base_opt $silent_opt $writeout_opt $resume_opt -o "$output_file" "$url"
			or begin; test -e "$output_file" && test (stat -c %s "$output_file") -eq 0 && rm "$output_file"; return 1; end
		else if test "$to_stdout" = "no"
			curl $base_opt $silent_opt $writeout_opt $resume_opt -O "$url" 1>&2 || return 1
		else
			curl $base_opt $silent_opt $writeout_opt $resume_opt "$url" || return 1
		end
		
		
	else if test "$use_tool" = "wget"
		test "$silent" = "yes" || echo "Download with wget ..." >&2
		set -l base_opt --max-redirect=10 --tries $retry_count --no-use-server-timestamps
		if $__cap_wget_has_glob
			set -a base_opt --no-glob
		end
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
			set -a base_opt --server-response
		else
			set -a base_opt --no-verbose
		end
		if test -n "$output_file"
			set final_opt -O "$output_file" "$url"
		else if test "$to_stdout" = "no"
			set final_opt "$url"
		else
			# TODO: redirecting STDOUT of wget2 in fedora 43 includes the progressbar
			set final_opt -O - "$url"
		end
		# switch to --verbose for very old versions of wget (Debian Wheezy)
		if set -q show_prog_opt && ! wget --help | string match -q -- "*--show-progress*"
			set show_prog_opt "--verbose"
		end
		wget $base_opt $silent_opt $show_prog_opt $resume_opt $final_opt
		or begin
			if test -n "$output_file" && test -e "$output_file" && test (stat -c %s "$output_file") -eq 0
				rm "$output_file"
			end
			return 1
		end
		
		
	else
		echo "Internal error" >&2
		return 1
	end
	
	# rename suggestion based on content if interactive and file was created
	if test -n "$output_file" && isatty 0 && test -e "$output_file" && type -q file
		set output_file (__sp_suggest_rename_file "$output_file")
	end
	
end
