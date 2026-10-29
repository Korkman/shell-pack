function td-sync-bin -d \
	"Sync shell-pack's bin symlinks with the repo, skipping downloaded dependencies"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td sync-bin"
		echo
		echo "  Add links in \$HOME/.local/share/shell-pack/bin for scripts new in the repo"
		echo "  and remove links to scripts that were deleted. Requires that src points"
		echo "  to the repo, see td edit-live. Downloaded dependencies (bat, dool.d, fresh,"
		echo "  fzf, localsend-cli, rg) are left alone."
		return 0
	end >&2

	set -l srcdir "$HOME/.local/share/shell-pack/src"
	if ! test -d "$srcdir/bin"
		echo "$srcdir/bin not found, run td edit-live first" >&2
		return 1
	end
	__sp_td_sync_bin "$srcdir/bin" "$HOME/.local/share/shell-pack/bin"
end
