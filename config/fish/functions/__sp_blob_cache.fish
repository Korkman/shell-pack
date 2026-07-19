function __sp_blob_cache -d \
	'Cache management for blobs. Write: echo DATA | __sp_blob_cache --set NAME EXPIRY. Read: __sp_blob_cache --get [--allow-stale] NAME'

	argparse 'set' 'get' 'allow-stale' 'status' 'clear' 'get-tmpfile' 'move-file=' 'compress=' -- $argv
	or return 1

	if not set -q _flag_set;
		and not set -q _flag_get;
		and not set -q _flag_get_tmpfile;
		and not set -q _flag_clear;
		and not set -q _flag_status
		echo "__sp_blob_cache: one of --set, --get, --status, --clear or --get-tmpfile is required" >&2
		return 1
	end

	set -l name $argv[1]
	set -l expiry $argv[2]

	# determine cache directory
	set -l cache_base
	if test -n "$XDG_CACHE_HOME"
		set cache_base "$XDG_CACHE_HOME"
	else
		set cache_base "$HOME/.cache"
	end
	set -l cache_dir "$cache_base/shell-pack/blob-cache"
	
	set -l compressor
	set -l uncompressor
	if test -z $_flag_compress
		if test -z $SP_BLOB_CACHE_COMPRESS
			# auto-detect available compressors
			if type -q zstd
				set _flag_compress zstd
			else if type -q lz4
				set _flag_compress lz4
			else if type -q gzip
				set _flag_compress gzip
			else
				set _flag_compress none
			end
		else
			set _flag_compress $SP_BLOB_CACHE_COMPRESS
		end
	end
	switch $_flag_compress
		case 'none'
			# none = cat
			set compressor cat
			set uncompressor cat
			set cache_dir "$cache_dir/cat"
		case 'gz' 'gzip'
			set compressor gzip -9
			set uncompressor gzip -d
			set cache_dir "$cache_dir/gzip"
		case 'lz4'
			set compressor lz4 -9
			set uncompressor lz4 -d
			set cache_dir "$cache_dir/lz4"
		case 'zstd'
			set compressor zstd -9
			set uncompressor zstd -d
			set cache_dir "$cache_dir/zstd"
		case '*'
			__sp_error "Unsupported compressor: $_flag_compress"
			return 1
	end
	
	if test -z "$name" && ! set -q _flag_get_tmpfile
		echo "__sp_blob_cache: NAME is required" >&2
		return 1
	end

	# compute md5 of the name (pipe through __sp_getmd5 stdin form)
	set -l name_md5 (echo -n "$name" | __sp_getmd5)

	# --- GET-TMPFILE MODE: return a fresh temp file path in the cache dir ---
	if set -q _flag_get_tmpfile
		mkdir -p "$cache_dir"
		or return 1
		set -l tmp_file (mktemp "$cache_dir/.blob_cache_tmp.XXXXXX")
		or return 1
		echo "$tmp_file"
		return 0
	end
	
	# --- CLEAR MODE ---
	if set -q _flag_clear
		if test -d "$cache_dir"
			find "$cache_dir" -maxdepth 1 -name "*.$name_md5" -delete
		end
		return 0
	end

	# --- WRITE MODE ---
	if set -q _flag_set
		if test -z "$expiry"
			echo "__sp_blob_cache: EXPIRY is required with --set" >&2
			return 1
		end
		# parse optional suffix: 30s, 5m, 2h, 1d → absolute Unix timestamp
		if string match --quiet --regex -- '^[0-9]+[smhd]$' "$expiry"
			set -l amount (string replace --regex -- '[smhd]$' '' "$expiry")
			set -l unit (string replace --regex -- '^[0-9]+' '' "$expiry")
			set -l seconds $amount
			switch $unit
				case m
					set seconds (math "$amount * 60")
				case h
					set seconds (math "$amount * 3600")
				case d
					set seconds (math "$amount * 86400")
			end
			set expiry (math (date +%s) + $seconds)
		end

		mkdir -p "$cache_dir"
		or return 1

		set -l target "$cache_dir/$expiry.$name_md5"
		if set -q _flag_move_file
			if test "$compressor" = "cat"
				mv "$_flag_move_file" "$target"
			else
				cat "$_flag_move_file" | $compressor > "$target.new"
				rm "$_flag_move_file"
				mv "$target.new" "$target"
			end
			__sp_blob_cache_gc "$cache_dir" "$name_md5"
			return $status
		end

		set -l tmp_file (mktemp "$cache_dir/.blob_cache_tmp.XXXXXX")
		or return 1

		# read stdin into temp file
		$compressor > "$tmp_file"
		set -l cat_status $status

		if test $cat_status -ne 0
			rm -f "$tmp_file"
			return $cat_status
		end

		mv "$tmp_file" "$target"
		__sp_blob_cache_gc "$cache_dir" "$name_md5"
		return $status
	end

	# --- READ MODE ---
	if not test -d "$cache_dir"
		return 10
	end

	# list all cache files for this name, sorted by expiry desc
	set -l matches (find "$cache_dir" -maxdepth 1 -name "*.$name_md5" 2>/dev/null | sort -rn )

	if test (count $matches) -eq 0
		return 10
	end

	set -l cache_file $matches[1]
	set -l filename (basename "$cache_file")

	# extract expiry timestamp from filename (part before the first dot)
	set -l stored_expiry (string replace --regex -- '\..*$' '' "$filename")
	set -l now (date +%s)

	if test $now -gt $stored_expiry
		# expired
		if set -q _flag_allow_stale; and not set -q _flag_status
			cat "$cache_file" | $uncompressor
		end
		return 20
	end

	if not set -q _flag_status
		cat "$cache_file" | $uncompressor
	end
	return 0
end

function __sp_blob_cache_gc -a cache_dir -a name_md5
	# Delete all cache files expired more than 180 days ago
	set -l cutoff (math (date +%s) - 180 \* 86400)
	for f in (find "$cache_dir" -maxdepth 1 -type f -not -name '.*' 2>/dev/null)
		set -l fname (basename "$f")
		set -l fexpiry (string replace --regex -- '\..*$' '' "$fname")
		if string match --quiet --regex -- '^[0-9]+$' "$fexpiry"
			if test $fexpiry -lt $cutoff
				rm -f "$f"
			end
		end
	end

	# For the current name, keep only the file with the longest (highest) expiry
	if test -n "$name_md5"
		set -l name_files (find "$cache_dir" -maxdepth 1 -name "*.$name_md5" 2>/dev/null | sort -rn)
		if test (count $name_files) -gt 1
			for f in $name_files[2..]
				rm -f "$f"
			end
		end
	end
end