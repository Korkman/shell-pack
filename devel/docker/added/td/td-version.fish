function td-version -d \
	"Checkout a specific version of shell-pack"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td version [TAG]"
		echo
		echo "  Reinstall shell-pack from the /repo checkout using get.sh's local"
		echo "  git detection. TAG defaults to 'worktree' (a snapshot of /repo's"
		echo "  current working tree, including uncommitted/untracked changes)."
		echo "  Any other TAG is checked out via git in a scratch copy."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	if ! test -e /repo/get.sh
		echo "/repo/get.sh not found, was the repo mounted read-only as /repo?" >&2
		return 1
	end

	set -e __sp_last_date_check_deps
	rm -rf $HOME/.local/share/shell-pack/src
	/repo/get.sh $argv
	exec fish
end
