function cfd -d \
	'Compressed file decompression'
	
	# stdin? really a moot point as the user can easily use the compressor directly
	# also, no easy way to detect the decompressor
	
	set filename (realpath "$argv[1]")
	set dst "$argv[2]"
	
	if ! test -e "$filename"
		echo "File does not exist: $filename" >&2
		return 1
	end
	set filename (__sp_suggest_rename_file "$filename")
	
	if isatty 1 || ! test -z "$dst"
	else
		set dst "/dev/stdout"
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
	
	if string match -qir '\.zip$' -- "$filename"
		__sp_require_cmd unzip || return 1
		__sp_cfd_make_dst_dir || return 2
		unzip "$filename" -d "$dst"
	else if string match -qir '\.(tar\.[^\.]+|tb2|tbz|tbz2|tz2|taz|tgz|tlz|txz|tZ|taZ|tzst)$' -- "$filename"
		__sp_require_cmd tar || return 1
		__sp_cfd_make_dst_dir || return 2
		tar -xf "$filename" -C "$dst"
	else if string match -qir '\.tar$' -- "$filename"
		__sp_require_cmd tar || return 1
		__sp_cfd_make_dst_dir || return 2
		tar -xf "$filename" -C "$dst"
	else if string match -qir '\.7z$' -- "$filename"
		__sp_require_cmd $bin_7z || return 1
		__sp_cfd_make_dst_dir || return 2
		$bin_7z x "$filename" -o"$dst"
	else if string match -qir '\.gz$' -- "$filename"
		__sp_require_cmd gunzip || return 1
		__sp_cfd_make_dst_file || return 2
		gunzip -c "$filename" > "$dst"
	else if string match -qir '\.zst$' -- "$filename"
		__sp_require_cmd zstd || return 1
		__sp_cfd_make_dst_file || return 2
		zstd --stdout -d "$filename" > "$dst"
	else if string match -qir '\.bz2$' -- "$filename"
		__sp_require_cmd bzip2 || return 1
		__sp_cfd_make_dst_file || return 2
		bzip2 --stdout -d "$filename" > "$dst"
	else if string match -qir '\.lz$' -- "$filename"
		__sp_require_cmd lzip || return 1
		__sp_cfd_make_dst_file || return 2
		lzip --stdout -d "$filename" > "$dst"
	else if string match -qir '\.lzma$' -- "$filename"
		__sp_require_cmd lzma || return 1
		__sp_cfd_make_dst_file || return 2
		lzma --stdout -d "$filename" > "$dst"
	else if string match -qir '\.lzo$' -- "$filename"
		__sp_require_cmd lzop || return 1
		__sp_cfd_make_dst_file || return 2
		lzop --stdout -d "$filename" > "$dst"
	else if string match -qir '\.xz$' -- "$filename"
		__sp_require_cmd xz || return 1
		__sp_cfd_make_dst_file || return 2
		xz --stdout -d "$filename" > "$dst"
	else if string match -qir '\.Z$' -- "$filename"
		__sp_require_cmd gzip || return 1
		__sp_cfd_make_dst_file || return 2
		gunzip -c "$filename" > "$dst"
	else
		echo "Unsupported file type" >&2
		return 1
	end
end

function __sp_cfd_make_dst_dir --no-scope-shadowing
	if test "$dst" = "/dev/stdout"
		echo "Cannot decompress directory structure to stdout" >&2
		return 1
	end
	if test -z "$dst"
		set dst (dirname -- "$filename")
	end
	if ! test -d "$dst"
		echo "Destination directory does not exist: $dst" >&2
		return 1
	end
end

function __sp_cfd_make_dst_file --no-scope-shadowing
	set -l filename_minus_ext (string replace -r '\.[^\.]+$' '' -- "$filename")
	if test -z "$dst"
		set dst "$filename_minus_ext"
	end
	if test -d "$dst"
		set dst (realpath "$dst")"/$filename_minus_ext"
	end
	if test -e "$dst"
		read -P "File '$dst' exists. Overwrite? (Y/n): " -l answer || set -l answer n
		if not string match -q -i 'y' "$answer" && ! test -z "$answer"
			echo "Aborted." >&2
			return 1
		end
	end
end
