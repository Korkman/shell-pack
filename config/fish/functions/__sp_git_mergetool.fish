# git mergetool: BASE LOCAL REMOTE MERGED (as set by git in $BASE $LOCAL $REMOTE $MERGED)
# Whichever side was edited becomes MERGED; editing both sides aborts
function __sp_git_mergetool -S -d "Edit LOCAL against REMOTE; copy the edited side to MERGED"
	if test (count $argv) -ne 4
		__sp_error "Usage: __sp_git_mergetool BASE LOCAL REMOTE MERGED"
		__sp_error "Was: ""$argv"
		return 1
	end
	set -l lfile $argv[2]
	set -l rfile $argv[3]
	set -l merged $argv[4]

	# snapshots allow content comparison; timestamps only have one-second resolution
	set -l snapdir (__sp_mkuniq --dir --xdg-runtime merge)
	or return 1
	cp -- "$lfile" "$snapdir/local"; or return 1
	cp -- "$rfile" "$snapdir/remote"; or return 1

	# same tool chain as the diff mode; fallbacks leave LOCAL unchanged, so the conflict stays unresolved
	if command -q fresh
		SHELL_PACK_MERGE_MODE=1 fresh --diff "$lfile" "$rfile"
	else if command -q mcdiff
		mcdiff -u "$lfile" "$rfile"
	else if command -q diff
		diff "$lfile" "$rfile"
	else
		__sp_error "No diff tool found"
	end

	set -l lchanged 0
	set -l rchanged 0
	if ! cmp -s -- "$lfile" "$snapdir/local"
		set lchanged 1
	end
	if ! cmp -s -- "$rfile" "$snapdir/remote"
		set rchanged 1
	end

	set -l status_code 0
	if test $lchanged -eq 1; and test $rchanged -eq 1
		__sp_error "Both sides were changed (\"$lfile\" and \"$rfile\")! Aborting ..."
		set status_code 1
	else if test $lchanged -eq 1
		echo "Change detected in LOCAL, overwriting \"$merged\""
		cp -- "$lfile" "$merged"
		or set status_code 1
	else if test $rchanged -eq 1
		echo "Change detected in REMOTE, overwriting \"$merged\" with it"
		cp -- "$rfile" "$merged"
		or set status_code 1
	else
		echo "No change detected, conflict unresolved."
		set status_code 1
	end

	rm -rf -- "$snapdir"
	return $status_code
end
