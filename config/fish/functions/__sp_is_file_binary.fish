function __sp_is_file_binary
	set -l file (path resolve -- $argv[1])
	if command -q file
		if test (file -b --mime-encoding -- $file) = binary
			return 0
		end
	else
		# no 'file' available: fall back to scanning the first MiB for a NUL byte, reading NUL-delimited records
		set -l records 0
		tail -c 1048576 -- $file | while read -z -l chunk
			set records (math $records + 1)
			if test $records -gt 1
				break
			end
		end
		if test $records -gt 1
			return 0
		end
	end
	return 1
end
