function __sp_merge_editor -d \
	'Diff two files for merging: fresh --diff when available, mcdiff otherwise'

	if test (count $argv) -ne 2
		__sp_error "Usage: __sp_merge_editor FILE_A FILE_B"
		return 1
	end
	
	if isatty stdout && command -q fresh
		SHELL_PACK_MERGE_MODE=1 fresh --diff $argv[1] $argv[2]
	else if isatty stdout && command -q mcdiff
		mcdiff -u $argv[1] $argv[2]
	else if command -q diff
		if command -q bat
			diff $argv[1] $argv[2] | bat --plain --color=always --language=diff
		else
			diff --color=always $argv[1] $argv[2]
		end
	else
		__sp_error "No diff tool found"
	end
end
