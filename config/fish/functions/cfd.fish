# When adding new formats here, do not forget to update completions and mc menu.

function cfd -d \
'Compressed file decompression'
	set -g __sp_cfd_tmp
	__sp_cfd_main $argv
	set -l ret $status
	if test (count $__sp_cfd_tmp) -gt 0
		command rm -f -- $__sp_cfd_tmp
	end
	set -e __sp_cfd_tmp
	return $ret
end

function __sp_cfd_main
	argparse 'h/help' 'get-type' 'deep' -- $argv
	or return 1
	
	if set -q _flag_help
		echo "Usage: cfd [ FILE|- [ DESTINATION ] ]"
		echo "       cfd DESTINATION < FILE"
		echo "       cfd --get-type [--deep] FILE"
		echo
		echo -e (functions -vD cfd)[5]
		echo
		echo "Decompress FILE in the current directory or at DESTINATION."
		echo "If the archive supports directories, DESTINATION is a directory."
		echo "If not, DESTINATION is the uncompressed filename."
		echo "DESTINATION '-' writes to stdout, which is also the default when stdout"
		echo "is not a terminal. Directory formats cannot be written to stdout."
		echo
		echo "When stdin is not a terminal, it is read as FILE: with no argument, or with"
		echo "a single argument which is then taken as DESTINATION."
		echo "FILE '-' reads from stdin. The format is detected by magic (needs 'file')."
		echo "Compressed tarballs on stdin are not detected as such; pipe through the"
		echo "decompressor and into 'cfd -' again. zip, 7z and squashfs need a seekable"
		echo "file and are refused on stdin."
		echo
		echo "--get-type  Print FILE's detected archive/compression format and exit."
		echo "--deep      With --get-type, also use 'file' magic detection when the"
		echo "            extension is not recognized."
		return 1
	end >&2
	
	# no FILE given and stdin is not a terminal: same as FILE "-"
	if test (count $argv) -eq 0
		if isatty 0
			echo "Missing FILE argument, see --help" >&2
			return 1
		end
		set argv -
	else if test (count $argv) -eq 1; and not set -q _flag_get_type; and not isatty 0
		# single argument and stdin is not a terminal: it is the destination
		set argv - $argv[1]
	end
	set dst "$argv[2]"
	set -l stdin_mode 0
	set -l head
	if test "$argv[1]" = "-"
		set stdin_mode 1
		set filename "-"
		# read exactly 1024 bytes (dd bs=1 never over-reads a pipe) for detection
		set head (__sp_mkuniq --xdg-runtime cfd-head)
		set -a __sp_cfd_tmp $head
		dd bs=1 count=1024 of="$head" 2>/dev/null
		if test (__sp_get_filesize "$head") -eq 0
			echo "No data on stdin" >&2
			return 1
		end
	else
		set filename (path resolve -- "$argv[1]")
		if ! test -e "$filename"
			echo "File does not exist: $filename" >&2
			return 1
		end
	end
	
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
	if test $stdin_mode -eq 1
		# no extension to go by
	else if string match -qir '\.zip$' -- "$filename"
		set format zip
	else if string match -qir '\.(tar\.[^\.]+|tb2|tbz|tbz2|tz2|taz|tgz|tlz|txz|tZ|taZ|tzst)$' -- "$filename"
		set format tar
	else if string match -qir '\.tar$' -- "$filename"
		set format tar
	else if string match -qir '\.cpio$' -- "$filename"
		set format cpio
	else if string match -qir '\.7z$' -- "$filename"
		set format 7z
	else if string match -qir '\.(squashfs|sqfs)$' -- "$filename"
		set format squashfs
	else if string match -qir '\.gz$' -- "$filename"
		set format gz
	else if string match -qir '\.zst$' -- "$filename"
		set format zst
	else if string match -qir '\.bz2$' -- "$filename"
		set format bz2
	else if string match -qir '\.br$' -- "$filename"
		set format br
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

	# Fall back to file(1) magic detection when extension gives no match.
	# For --get-type, this is only attempted with --deep.
	set -l try_magic 0
	if test -z "$format"
		if test $stdin_mode -eq 1
			set try_magic 1
		else if set -q _flag_get_type
			if set -q _flag_deep
				set try_magic 1
			end
		else
			set try_magic 1
		end
	end
	if test $try_magic -eq 1
		if ! command -q file
			if set -q _flag_get_type
				return 1
			end
			echo "Unsupported file type (install 'file' for magic-based detection)" >&2
			return 1
		end
		set -l probe "$filename"
		if test $stdin_mode -eq 1
			set probe "$head"
		end
		set -l mime (file --mime-type -b -- "$probe")
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
		else if string match -q '*squashfs*' -- "$mime"
			set format squashfs
		else
			if set -q _flag_get_type
				return 1
			end
			echo "Unsupported file type (MIME: $mime)" >&2
			return 1
		end
	end

	if set -q _flag_get_type
		if test -z "$format"
			return 1
		end
		echo "$format"
		return 0
	end

	# formats which need seeking cannot be read from a stream
	if test $stdin_mode -eq 1
		switch $format
		case zip 7z squashfs
			echo "Format '$format' cannot be read from stdin, save it to a file first." >&2
			return 1
		end
		if test -z "$dst"; and contains -- $format tar cpio
			set dst "."
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
		if test $stdin_mode -eq 1
			__sp_cfd_src | tar -xf - -C "$dst"
		else if string match -qir '\.tar\.br$' -- "$filename"
			# tar has no builtin brotli support
			__sp_require_cmd brotli || return 1
			brotli --stdout -d "$filename" | tar -xf - -C "$dst"
		else
			tar -xf "$filename" -C "$dst"
		end
	case cpio
		__sp_require_cmd cpio || return 1
		__sp_cfd_make_dst_dir || return 2
		pushd "$dst"
		if test $stdin_mode -eq 1
			__sp_cfd_src | cpio -id
		else
			cpio -id < "$filename"
		end
		popd
	case 7z
		__sp_require_cmd $bin_7z || return 1
		__sp_cfd_make_dst_dir || return 2
		$bin_7z x "$filename" -o"$dst"
	case squashfs
		if ! command -vq unsquashfs || set -q CFC_FORCE_RDSQUASHFS; and command -vq rdsquashfs
			__sp_cfd_make_dst_dir || return 2
			rdsquashfs -u / -p "$dst" "$filename"
			return
		end
		__sp_require_cmd unsquashfs || return 1
		__sp_cfd_make_dst_dir || return 2
		# -f lets unsquashfs write into the already-created destination directory
		unsquashfs -f -d "$dst" "$filename"
	case gz
		__sp_require_cmd gunzip || return 1
		__sp_cfd_make_dst_file || return 2
		__sp_cfd_src | gunzip -c | __sp_redirect_out "$dst"
	case zst
		__sp_require_cmd zstd || return 1
		__sp_cfd_make_dst_file || return 2
		__sp_cfd_src | zstd --stdout -d | __sp_redirect_out "$dst"
	case br
		__sp_require_cmd brotli || return 1
		__sp_cfd_make_dst_file || return 2
		__sp_cfd_src | brotli --stdout -d | __sp_redirect_out "$dst"
	case bz2
		__sp_require_cmd bzip2 || return 1
		__sp_cfd_make_dst_file || return 2
		__sp_cfd_src | bzip2 --stdout -d | __sp_redirect_out "$dst"
	case lz4
		__sp_require_cmd lz4 || return 1
		__sp_cfd_make_dst_file || return 2
		__sp_cfd_src | lz4 -d -c | __sp_redirect_out "$dst"
	case lz
		__sp_require_cmd lzip || return 1
		__sp_cfd_make_dst_file || return 2
		__sp_cfd_src | lzip --stdout -d | __sp_redirect_out "$dst"
	case lzma
		__sp_require_cmd lzma || return 1
		__sp_cfd_make_dst_file || return 2
		__sp_cfd_src | lzma --stdout -d | __sp_redirect_out "$dst"
	case lzo
		__sp_require_cmd lzop || return 1
		__sp_cfd_make_dst_file || return 2
		__sp_cfd_src | lzop --stdout -d | __sp_redirect_out "$dst"
	case xz
		__sp_require_cmd xz || return 1
		__sp_cfd_make_dst_file || return 2
		__sp_cfd_src | xz --stdout -d | __sp_redirect_out "$dst"
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
		set -l answer
		__sp_cfd_read ""
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
	if test $stdin_mode -eq 1
		if test -z "$dst"
			echo "Destination required when reading stdin" >&2
			return 1
		end
		set filename_minus_ext stdin
	end
	if test -z "$dst"
		set dst "$filename_minus_ext"
	end
	if test -d "$dst"
		set dst (builtin path resolve "$dst")"/"(path basename -- "$filename_minus_ext")
	end
	# only regular files need confirmation; devices and fifos (e.g. /dev/null) do not
	if test -f "$dst"
		set -l answer
		__sp_cfd_read "File '$dst' exists. Overwrite? (Y/n): "
		if not string match -q -i 'y' "$answer" && ! test -z "$answer"
			echo "Aborted." >&2
			return 1
		end
	end
end

# emit the input: stdin (after the detection head) or the file
function __sp_cfd_src --no-scope-shadowing
	if test $stdin_mode -eq 1
		cat "$head" -
	else
		cat -- "$filename"
	end
end

# prompt without consuming the data stream on stdin; sets $answer in the caller
# (command substitution would lose stdin, so a global is used)
function __sp_cfd_read --no-scope-shadowing -a prompt
	set -g __sp_cfd_answer n
	if test $stdin_mode -eq 1
		read -P "$prompt" -g __sp_cfd_answer < /dev/tty; or set __sp_cfd_answer n
	else
		read -P "$prompt" -g __sp_cfd_answer; or set __sp_cfd_answer n
	end
	set answer $__sp_cfd_answer
	set -e __sp_cfd_answer
end
