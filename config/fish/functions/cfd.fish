function cfd -d \
'Compressed file decompression'
	
	if set -q argv[1] && test "$argv[1]" = "--help"
		echo "Usage: cfd FILE [ DESTINATION ]"
		echo
		echo -e (functions -vD (status current-function))[5]
		echo
		echo "Decompress FILE in the current directory or at DESTINATION."
		echo "If the archive supports directories, DESTINATION is a directory."
		echo "If not, DESTINATION is the uncompressed filename."
		return 1
	end >&2
	
	set filename (realpath "$argv[1]")
	set dst "$argv[2]"
	
	if ! test -e "$filename"
		echo "File does not exist: $filename" >&2
		return 1
	end
	set filename (__sp_suggest_rename_file "$filename")
	
	# when no dst given and stdout is not a terminal, decompress to stdout
	if test -z "$dst" && not isatty 1
		set dst "-"
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
	
	# Detect format from file extension
	set -l format ""
	if string match -qir '\.zip$' -- "$filename"
		set format zip
	else if string match -qir '\.(tar\.[^\.]+|tb2|tbz|tbz2|tz2|taz|tgz|tlz|txz|tZ|taZ|tzst)$' -- "$filename"
		set format tar
	else if string match -qir '\.tar$' -- "$filename"
		set format tar
	else if string match -qir '\.cpio$' -- "$filename"
		set format cpio
	else if string match -qir '\.7z$' -- "$filename"
		set format 7z
	else if string match -qir '\.gz$' -- "$filename"
		set format gz
	else if string match -qir '\.zst$' -- "$filename"
		set format zst
	else if string match -qir '\.bz2$' -- "$filename"
		set format bz2
	else if string match -qir '\.lz4$' -- "$filename"
		set format lz4
	else if string match -qir '\.lz$' -- "$filename"
		set format lz
	else if string match -qir '\.lzma$' -- "$filename"
		set format lzma
	else if string match -qir '\.lzo$' -- "$filename"
		set format lzo
	else if string match -qir '\.xz$' -- "$filename"
		set format xz
	else if string match -qir '\.Z$' -- "$filename"
		set format gz
	end

	# Fall back to file(1) magic detection when extension gives no match
	if test -z "$format"
		if ! command -q file
			echo "Unsupported file type (install 'file' for magic-based detection)" >&2
			return 1
		end
		set -l mime (file --mime-type -b -- "$filename")
		if string match -q 'application/zip' -- "$mime"
			set format zip
		else if string match -q 'application/x-tar' -- "$mime"
			set format tar
		else if string match -q 'application/x-7z-compressed' -- "$mime"
			set format 7z
		else if string match -q 'application/gzip' -- "$mime"; or string match -q 'application/x-gzip' -- "$mime"
			set format gz
		else if string match -q 'application/x-bzip2' -- "$mime"
			set format bz2
		else if string match -q 'application/x-xz' -- "$mime"
			set format xz
		else if string match -q 'application/zstd' -- "$mime"; or string match -q 'application/x-zstd' -- "$mime"
			set format zst
		else if string match -q 'application/x-lz4' -- "$mime"
			set format lz4
		else if string match -q 'application/x-lzma' -- "$mime"
			set format lzma
		else if string match -q 'application/x-lzip' -- "$mime"
			set format lz
		else if string match -q 'application/x-lzop' -- "$mime"
			set format lzo
		else if string match -q 'application/x-cpio' -- "$mime"
			set format cpio
		else
			echo "Unsupported file type (MIME: $mime)" >&2
			return 1
		end
	end

	# Dispatch to the appropriate decompressor
	switch $format
	case zip
		__sp_require_cmd unzip || return 1
		__sp_cfd_make_dst_dir || return 2
		unzip "$filename" -d "$dst"
	case tar
		__sp_require_cmd tar || return 1
		__sp_cfd_make_dst_dir || return 2
		tar -xf "$filename" -C "$dst"
	case cpio
		__sp_require_cmd cpio || return 1
		__sp_cfd_make_dst_dir || return 2
		pushd "$dst"
		cpio -id < "$filename"
		popd
	case 7z
		__sp_require_cmd $bin_7z || return 1
		__sp_cfd_make_dst_dir || return 2
		$bin_7z x "$filename" -o"$dst"
	case gz
		__sp_require_cmd gunzip || return 1
		__sp_cfd_make_dst_file || return 2
		gunzip -c "$filename" | __sp_redirect_out "$dst"
	case zst
		__sp_require_cmd zstd || return 1
		__sp_cfd_make_dst_file || return 2
		zstd --stdout -d "$filename" | __sp_redirect_out "$dst"
	case bz2
		__sp_require_cmd bzip2 || return 1
		__sp_cfd_make_dst_file || return 2
		bzip2 --stdout -d "$filename" | __sp_redirect_out "$dst"
	case lz4
		__sp_require_cmd lz4 || return 1
		__sp_cfd_make_dst_file || return 2
		lz4 --stdout -d "$filename" | __sp_redirect_out "$dst"
	case lz
		__sp_require_cmd lzip || return 1
		__sp_cfd_make_dst_file || return 2
		lzip --stdout -d "$filename" | __sp_redirect_out "$dst"
	case lzma
		__sp_require_cmd lzma || return 1
		__sp_cfd_make_dst_file || return 2
		lzma --stdout -d "$filename" | __sp_redirect_out "$dst"
	case lzo
		__sp_require_cmd lzop || return 1
		__sp_cfd_make_dst_file || return 2
		lzop --stdout -d "$filename" | __sp_redirect_out "$dst"
	case xz
		__sp_require_cmd xz || return 1
		__sp_cfd_make_dst_file || return 2
		xz --stdout -d "$filename" | __sp_redirect_out "$dst"
	end
end

function __sp_cfd_make_dst_dir --no-scope-shadowing
	if test "$dst" = "-"
		echo "Cannot decompress directory structure to stdout" >&2
		return 1
	end
	if test -z "$dst"
		set dst (dirname -- "$filename")
	end
	if test -f "$dst"
		echo "Destination is a file but the archive format supports directories." >&2
		return 1
	end
	if ! test -d "$dst"
		echo "Destination directory does not exist: $dst"
		echo -n "Create (Y/n)?"
		read -P "" -l answer || set -l answer n
		if ! test "$answer" = "y" && ! test "$answer" = "Y" && ! test "$answer" = ""
			return 1
		end
		if ! mkdir -p "$dst"
			echo "Failed to create directory"
			return 1
		end
	end >&2
end

function __sp_cfd_make_dst_file --no-scope-shadowing
	if test "$dst" = "-"
		# piping to stdout
		return
	end
	set -l filename_minus_ext (string replace -r '\.[^\.]+$' '' -- "$filename")
	if test -z "$dst"
		set dst "$filename_minus_ext"
	end
	if test -d "$dst"
		set dst (builtin path resolve "$dst")"/$filename_minus_ext"
	end
	if test -e "$dst"
		read -P "File '$dst' exists. Overwrite? (Y/n): " -l answer || set -l answer n
		if not string match -q -i 'y' "$answer" && ! test -z "$answer"
			echo "Aborted." >&2
			return 1
		end
	end
end
