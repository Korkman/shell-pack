function __sp_is_file_binary
	set -l file (path resolve -- $argv[1])
	if command -q file
		if test (file -b --mime-encoding -- $file) = binary
			return 0
		end
	else
		# no 'file' available: fall back to scanning the first MiB for a NUL byte, stopping at the first one found
		if tail -c 1048576 -- $file | awk -- 'BEGIN{RS="\0"; nul=0} NR==2{nul=1; exit} END{exit (nul?0:1)}'
			return 0
		end
	end
	return 1
end
