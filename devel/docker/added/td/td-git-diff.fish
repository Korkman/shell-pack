function td-git-diff -d \
	"Create a repo with a change in f.txt, wired to the __sp_git_difftool difftool"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td git-diff"
		echo
		echo "  Creates a repo in a fresh temporary directory with an uncommitted change"
		echo "  in f.txt, configured to use __sp_git_difftool as difftool. Prints"
		echo "  the commands to run it; the directory is left behind for manual testing."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	need --ask git; or return 1

	set -l tmp (__sp_mkuniq --dir --xdg-runtime td-git-diff)
	or return 1

	git -C "$tmp" init -q; or return 1
	git -C "$tmp" config user.name td
	git -C "$tmp" config user.email td@example.invalid
	git -C "$tmp" config commit.gpgsign false

	printf 'base\n' > "$tmp/f.txt"
	git -C "$tmp" add f.txt; or return 1
	git -C "$tmp" commit -qm base; or return 1
	printf 'changed\n' > "$tmp/f.txt"

	echo "Diff repo created: $tmp"
	echo
	echo "Run the difftool with:"
	echo "  git difftool"
	echo
	echo "Remove the directory when done: rm -rf $tmp"
	
	cd -- "$tmp"
end
