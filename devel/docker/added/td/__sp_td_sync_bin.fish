function __sp_td_sync_bin -d \
	"Sync symlinks in shell-pack's bin dir with a source bin dir, skipping downloaded dependencies"
	set -l srcbin $argv[1]
	set -l bindir $argv[2]

	# a bin dir that is itself a symlink (see switch-user-to-devel) already is the source bin dir
	if test -L "$bindir"
		return 0
	end
	mkdir -p "$bindir"

	# installed by shell-pack-deps as real files, they may be incompatible with the repo's copies, so never link them
	set -l downloaded bat dool.d fresh fzf localsend-cli rg

	# add links for scripts in the repo, like get.sh does
	for item in $srcbin/*
		set -l name (basename $item)
		contains -- $name $downloaded; and continue
		set -l link "$bindir/$name"
		if test -L "$link"
			set -l target (readlink "$link")
			test "$target" = "../src/bin/$name"; and continue
			rm "$link"
		else if test -e "$link"
			# a real file, not one of ours
			continue
		end
		ln -s "../src/bin/$name" "$link"
		echo "Linked $name"
	end

	# remove links to scripts that no longer exist in the repo
	for link in $bindir/*
		test -L "$link"; or continue
		set -l target (readlink "$link")
		string match -q '../src/bin/*' -- "$target"; or continue
		set -l name (basename "$link")
		test -e "$srcbin/$name"; and continue
		rm "$link"
		echo "Removed stale $name"
	end
end
