function cfc -d \
	'Compressed file creation'
	
	if test (count $argv) -eq 0
		echo "Usage: cfc FILE|DIR [ DEST ] [-- (compressor arguments like -9) ]"
		echo "  DEST can be a format like tar.gz or a complete filename including extension"
		echo "  Output redirection is detected and supported"
		return 1
	end >&2
	
	# filter out passed args and keep own
	set -l passed_args
	set -l args
	set -l search_passed_args no
	for arg in $argv
		if test "$search_passed_args" = "yes"
			set -a passed_args "$arg"
		else
			if test "$arg" = "--"
				set search_passed_args yes
				continue
			end
			set -a args "$arg"
		end
	end
	set argv $args
	
	set -l ext
	set -l comprext '('
	# tar and its many filename extensions
	set comprext $comprext'tar'
	set comprext $comprext'|tar\.gz|taz|tgz'
	set comprext $comprext'|tar\.zst|tzst'
	set comprext $comprext'|tar\.bz2|tb2|tbz|tbz2|tz2'
	set comprext $comprext'|tar\.lz'
	set comprext $comprext'|tar\.lzma|tlz'
	set comprext $comprext'|tar\.lzo'
	set comprext $comprext'|tar\.lz4'
	set comprext $comprext'|tar\.xz|txz'
	set comprext $comprext'|tar\.Z|tZ|taZ'
	# more directory compressors
	set comprext $comprext'|7z'
	set comprext $comprext'|zip'
	# single file compressors
	set comprext $comprext'|gz'
	set comprext $comprext'|bz2'
	set comprext $comprext'|lz'
	set comprext $comprext'|lzma'
	set comprext $comprext'|lzo'
	set comprext $comprext'|xz'
	set comprext $comprext'|Z'
	set comprext $comprext'|lz4'
	set comprext $comprext'|zst'
	set comprext $comprext')$'
	
	# choose a default compression method if none is given
	set -l defext 'gz'
	set -l defdirext 'tar.gz'
	if type -q zstd
		set defext 'zst'
		set defdirext 'tar.zst'
	else if type -q xz
		set defext 'xz'
		set defdirext 'tar.xz'
	end
	
	# select best 7z binary available
	set -l bin_7z "7z"
	if ! type -q 7z
		if type -q 7zz
			set bin_7z "7zz"
		else if type -q 7za
			set bin_7z "7za"
		else if type -q 7zr
			set bin_7z "7zr"
		end
	end
	
	if isatty 1
		if test (count $argv) -eq 0
			read -c '../'(basename (realpath .))".tar.$defext" -P "Compress current dir to filename: " -l answer
			set argv[1] "$answer"
		end
		
		if test (count $argv) -eq 1
			if string match -q -r "^$comprext" "$argv[1]"
				# a compressor was given - compressing pwd
				set src .
				set filename ../(basename (realpath .))"$argv[1]"
			else if ! string match -q -r "\.$comprext" "$argv[1]"
				# an existing file or directory was given
				set src (realpath "$argv[1]")
				if test "$src" = "/"
					set filename "/rootfs.$defdirext"
				else if test -d "$src"
					set filename "$src.$defdirext"
				else
					set filename "$src.$defext"
				end
			else
				# only a destination file was given - compressing pwd
				if not string match -q -r '/' "$argv[1]"
					# only a filename? compress to one dir up
					set src .
					set filename ../"$argv[1]"
				else
					set src .
					set filename "$argv[1]"
				end
			end
		else if test (count $argv) -eq 2
			set src (realpath "$argv[1]")
			set filename "$argv[2]"
		else
			echo "Too many arguments" >&2
			return 1
		end
		
		if string match -q -r "^$comprext" "$filename"
			set filename (basename "$src")".$filename"
		end
		
		if test -e "$filename"
			read -P "File '$filename' exists. Overwrite? (Y/n): " -l answer || set -l answer n
			if not string match -q -i 'y' "$answer" && ! test -z "$answer"
				echo "Aborted." >&2
				return 1
			end
		end
		set ext (string match -r "\.$comprext" "$filename")
		set ext $ext[2]
	else
		set to_stdout yes
		if test (count $argv) -eq 0
			set ext "$defext"
		else if test (count $argv) -eq 1
			if string match -q -r "^$comprext" "$argv[1]"
				set ext "$argv[1]"
				set src .
			else
				set src (realpath "$argv[1]")
				if test -d "$src"
					set ext "$defdirext"
				else
					set ext "$defext"
				end
			end
		else if test (count $argv) -eq 2
			set src "$argv[1]"
			set ext "$argv[2]"
		else
			echo "Too many arguments" >&2
			return 1
		end
	end
	
	if test "$src" = "/"
		set tar_base_opts --one-file-system -c /
	else if test -d "$src"
		set tar_base_opts --one-file-system -C "$src/.." -c (basename "$src")
	else
		set tar_base_opts --one-file-system -C (dirname $src) -c (basename "$src")
	end
	
	if [ "$to_stdout" != "yes" ]
		echo "Compressing $src to $filename ..." >&2
		switch "$ext"
			case 'tar'
				__sp_require_cmd tar || return 1
				tar $tar_base_opts > "$filename"
			case 'tar.gz' 'taz' 'tgz'
				__sp_require_cmd tar || return 1
				__sp_require_cmd gzip || return 1
				tar $tar_base_opts | gzip $passed_args > "$filename"
			case 'tar.bz2' 'tb2' 'tbz' 'tbz2' 'tz2'
				__sp_require_cmd tar || return 1
				__sp_require_cmd bzip2 || return 1
				tar $tar_base_opts | bzip2 $passed_args > "$filename"
			case 'tar.lz'
				__sp_require_cmd tar || return 1
				__sp_require_cmd lzip || return 1
				tar $tar_base_opts | lzip $passed_args > "$filename"
			case 'tar.lzma' 'tlz'
				__sp_require_cmd tar || return 1
				__sp_require_cmd lzma || return 1
				tar $tar_base_opts | lzma $passed_args > "$filename"
			case 'tar.lzo'
				__sp_require_cmd tar || return 1
				__sp_require_cmd lzop || return 1
				tar $tar_base_opts | lzop $passed_args > "$filename"
			case 'tar.xz' 'txz'
				__sp_require_cmd tar || return 1
				__sp_require_cmd xz || return 1
				tar $tar_base_opts | xz $passed_args > "$filename"
			case 'tar.Z' 'tZ' 'taZ'
				__sp_require_cmd tar || return 1
				__sp_require_cmd compress || return 1
				tar $tar_base_opts | compress $passed_args > "$filename"
			case 'tar.lz4'
				__sp_require_cmd tar || return 1
				__sp_require_cmd lz4 || return 1
				tar $tar_base_opts | lz4 $passed_args > "$filename"
			case 'tar.zst' 'tzst'
				__sp_require_cmd tar || return 1
				__sp_require_cmd zstd || return 1
				tar $tar_base_opts | zstd $passed_args > "$filename"
			case 'zip'
				__sp_require_cmd zip || return 1
				set filename (realpath "$filename")
				cd "$src/.."
				zip $passed_args -r "$filename" (basename "$src")
				cd -
			case '7z'
				__sp_require_cmd $bin_7z || return 1
				$bin_7z a $passed_args "$filename" "$src"
			case 'gz'
				__sp_require_cmd gzip || return 1
				gzip $passed_args -c "$src" > "$filename"
			case 'bz2'
				__sp_require_cmd bzip2 || return 1
				bzip2 $passed_args -c "$src" > "$filename"
			case 'lz'
				__sp_require_cmd lzip || return 1
				lzip $passed_args -c "$src" > "$filename"
			case 'lzma'
				__sp_require_cmd lzma || return 1
				lzma $passed_args -c "$src" > "$filename"
			case 'lzo'
				__sp_require_cmd lzop || return 1
				lzop $passed_args -c "$src" > "$filename"
			case 'xz'
				__sp_require_cmd xz || return 1
				xz $passed_args -c "$src" > "$filename"
			case 'Z'
				__sp_require_cmd compress || return 1
				compress $passed_args -c "$src" > "$filename"
			case 'lz4'
				__sp_require_cmd lz4 || return 1
				lz4 $passed_args -c "$src" > "$filename"
			case 'zst'
				__sp_require_cmd zstd || return 1
				zstd $passed_args -c "$src" > "$filename"
			case '*'
				echo "Unsupported file extension" >&2
				return 1
		end
		set -l comp_pipestatus $pipestatus
		if test "$comp_pipestatus" != "0 0" && test "$comp_pipestatus" != "0"
			echo "Error compressing $src to $filename" >&2
			echo "Pipestatus: $comp_pipestatus" >&2
			return 1
		end
		set -l filesize (__sp_get_filesize "$filename")
		set -l filesize_mb (math "round($filesize / 1024 / 1024)")
		echo "Created $filename, $filesize bytes ($filesize_mb MiB)" >&2
	else
		echo "Compressing $src to stdout ..." >&2
		switch "$ext"
			case 'tar'
				__sp_require_cmd tar || return 1
				tar $tar_base_opts
			case 'tar.gz' 'taz' 'tgz'
				__sp_require_cmd tar || return 1
				__sp_require_cmd gzip || return 1
				tar $tar_base_opts | gzip $passed_args
			case 'tar.bz2' 'tb2' 'tbz' 'tbz2' 'tz2'
				__sp_require_cmd tar || return 1
				__sp_require_cmd bzip2 || return 1
				tar $tar_base_opts | bzip2 $passed_args
			case 'tar.lz'
				__sp_require_cmd tar || return 1
				__sp_require_cmd lzip || return 1
				tar $tar_base_opts | lzip $passed_args
			case 'tar.lzma' 'tlz'
				__sp_require_cmd tar || return 1
				__sp_require_cmd lzma || return 1
				tar $tar_base_opts | lzma $passed_args
			case 'tar.lzo'
				__sp_require_cmd tar || return 1
				__sp_require_cmd lzop || return 1
				tar $tar_base_opts | lzop $passed_args
			case 'tar.xz' 'txz'
				__sp_require_cmd tar || return 1
				__sp_require_cmd xz || return 1
				tar $tar_base_opts | xz $passed_args
			case 'tar.Z' 'tZ' 'taZ'
				__sp_require_cmd tar || return 1
				__sp_require_cmd compress || return 1
				tar $tar_base_opts | compress $passed_args
			case 'tar.lz4'
				__sp_require_cmd tar || return 1
				__sp_require_cmd lz4 || return 1
				tar $tar_base_opts | lz4 $passed_args
			case 'tar.zst' 'tzst'
				__sp_require_cmd tar || return 1
				__sp_require_cmd zstd || return 1
				tar $tar_base_opts | zstd $passed_args
			case 'zip'
				__sp_require_cmd zip || return 1
				cd "$src/.."
				zip $passed_args -r - (basename "$src")
				cd -
			case '7z'
				__sp_require_cmd $bin_7z || return 1
				echo "The 7z compressor cannot stream to stdout, it needs seek operations" >&2
				return 1
				$bin_7z a $passed_args -so "$src"
			case 'gz'
				__sp_require_cmd gzip || return 1
				gzip $passed_args -c "$src"
			case 'bz2'
				__sp_require_cmd bzip2 || return 1
				bzip2 $passed_args -c "$src"
			case 'lz'
				__sp_require_cmd lzip || return 1
				lzip $passed_args -c "$src"
			case 'lzma'
				__sp_require_cmd lzma || return 1
				lzma $passed_args -c "$src"
			case 'lzo'
				__sp_require_cmd lzop || return 1
				lzop $passed_args -c "$src"
			case 'xz'
				__sp_require_cmd xz || return 1
				xz $passed_args -c "$src"
			case 'Z'
				__sp_require_cmd gzip || return 1
				gzip -d $passed_args -c "$src"
			case 'lz4'
				__sp_require_cmd lz4 || return 1
				lz4 $passed_args -c "$src"
			case 'zst'
				__sp_require_cmd zstd || return 1
				zstd $passed_args -c "$src"
			case '*'
				echo "Unsupported file extension" >&2
				return 1
		end
		set -l comp_pipestatus $pipestatus
		if test "$comp_pipestatus" != "0 0" && test "$comp_pipestatus" != "0"
			echo "Error compressing $src to $filename" >&2
			echo "Pipestatus: $comp_pipestatus" >&2
			return 1
		end
	end
	
end
