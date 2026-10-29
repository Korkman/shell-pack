function td-edit-live -d \
	"Symlink shell-pack's src dir to /repo for live editing from the host"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td edit-live"
		echo
		echo "  Replace \$HOME/.local/share/shell-pack/src with a symlink to /repo,"
		echo "  so edits made on the host (outside the container) take effect"
		echo "  immediately, without needing to rerun td version."
		echo
		echo "  Also syncs the symlinks in \$HOME/.local/share/shell-pack/bin with /repo/bin:"
		echo "  links for new scripts are added and links to removed scripts are deleted."
		echo "  Downloaded dependencies (bat, dool.d, fresh, fzf, localsend-cli, rg) are"
		echo "  left alone. The sync is repeated on every fish start through"
		echo "  \$HOME/.config/fish/conf.d/shell-pack-sync-bin.fish, see td sync-bin."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	if ! test -e /repo/get.sh
		echo "/repo/get.sh not found, was the repo mounted read-only as /repo?" >&2
		return 1
	end

	set -l srcdir "$HOME/.local/share/shell-pack/src"
	rm -rf "$srcdir"
	ln -s /repo "$srcdir"
	echo "Linked $srcdir -> /repo"
	td-sync-bin

	# re-sync the bin links whenever a new fish starts, so scripts added to /repo show up without rerunning td edit-live
	set -l confdir "$HOME/.config/fish/conf.d"
	mkdir -p "$confdir"
	printf '%s\n' \
		'if functions -q td' \
		'    td sync-bin' \
		'end' >"$confdir/shell-pack-sync-bin.fish"
	echo "Installed $confdir/shell-pack-sync-bin.fish"

	set -e __sp_last_date_check_deps
	exec fish
end
