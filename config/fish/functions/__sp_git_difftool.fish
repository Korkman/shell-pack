# git difftool: LOCAL REMOTE (as set by git in $LOCAL $REMOTE)
function __sp_git_difftool -d "Diff LOCAL against REMOTE via __sp_merge_editor"
	if test (count $argv) -ne 2
		__sp_error "Usage: __sp_git_difftool LOCAL REMOTE"
		__sp_error "Was: ""$argv"
		return 1
	end

	# git difftool --dir-diff hands over two directories instead of two files;
	# git does not pass the flag on, so the directories are the only signal
	if test -d $argv[1]; or test -d $argv[2]
		__sp_error "Unsupported: git difftool --dir-diff (directory mode) is not implemented yet"
		return 1
	end

	__sp_merge_editor $argv[1] $argv[2]
end
