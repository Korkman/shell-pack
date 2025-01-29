function cfd -d \
	'Compressed file decompression'
	set filename (realpath "$argv[1]")
	set dst "$argv[2]"
	
	if ! test -e "$filename"
		echo "File does not exist: $filename"
		return 1
	end
	set filename (__sp_suggest_rename_file "$filename")
	
	# TODO: stdin? stdout?
	
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
	
	if string match -qr '\.zip$' -- "$filename"
		__sp_require_cmd unzip || return 1
		if test -z "$dst"; set dst (dirname -- "$filename"); end
		unzip "$filename" -d "$dst"
	else if string match -qr '\.(tar\.[^\.]+|tgz)$' -- "$filename"
		__sp_require_cmd tar || return 1
		if test -z "$dst"; set dst (dirname -- "$filename"); end
		tar -xaf "$filename" -C "$dst"
	else if string match -qr '\.tar$' -- "$filename"
		__sp_require_cmd tar || return 1
		if test -z "$dst"; set dst (dirname -- "$filename"); end
		tar -xf "$filename" -C "$dst"
	else if string match -qr '\.7z$' -- "$filename"
		__sp_require_cmd $bin_7z || return 1
		if test -z "$dst"; set dst (dirname -- "$filename"); end
		$bin_7z x "$filename" -o"$dst"
	else if string match -qr '\.gz$' -- "$filename"
		__sp_require_cmd gunzip || return 1
		if test -z "$dst"; set dst (string replace -r '\.gz$' '' -- "$filename"); end
		gunzip -c "$filename" > "$dst"
	else if string match -qr '\.zst$' -- "$filename"
		__sp_require_cmd zstd || return 1
		if test -z "$dst"; set dst (string replace -r '\.zst$' '' -- "$filename"); end
		zstd --stdout -d "$filename" > "$dst"
	else if string match -qr '\.bz2$' -- "$filename"
		__sp_require_cmd bzip2 || return 1
		if test -z "$dst"; set dst (string replace -r '\.bz2$' '' -- "$filename"); end
		bzip2 --stdout -d "$filename" > "$dst"
	else if string match -qr '\.xz$' -- "$filename"
		__sp_require_cmd xz || return 1
		if test -z "$dst"; set dst (string replace -r '\.xz$' '' -- "$filename"); end
		xz -d "$filename" > "$dst"
	else
		echo "Unsupported file type"
		return 1
	end
end
