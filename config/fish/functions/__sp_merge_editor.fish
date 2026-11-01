function __sp_merge_editor -d \
	'Diff two files for merging: fresh --diff when available, mcdiff otherwise'

	if test (count $argv) -ne 2
		__sp_error "Usage: __sp_merge_editor FILE_A FILE_B"
		return 1
	end

	if command -q fresh
		SHELL_PACK_MERGE_MODE=1 fresh --diff $argv[1] $argv[2]
	else
		mcdiff -u $argv[1] $argv[2]
	end
end
