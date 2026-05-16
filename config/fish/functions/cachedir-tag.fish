function cachedir-tag --description "Create a CACHEDIR.TAG file in the specified directory"
	argparse 'h/help' -- $argv
	or return

	if set -q _flag_help
		echo "Usage: cachedir-tag [DIRECTORY...]"
		echo "Creates a CACHEDIR.TAG file in each specified directory (default: current directory)."
		return 0
	end

	set -l dirs $argv
	if test (count $dirs) -eq 0
		set dirs .
	end

	for dir in $dirs
		if not test -d $dir
			echo "cachedir-tag: not a directory: $dir" >&2
			return 1
		end
		
		set -l tagfile $dir/CACHEDIR.TAG
		if test -f $tagfile
			echo "INFO: file exists: $tagfile" >&2
			return 0
		end
		
		printf '%s\n' \
			"Signature: 8a477f597d28d172789f06886806bc55" \
			"# This file is a cache directory tag created by cachedir-tag, a fish shell function from korkman/shell-pack" \
			"# For information about cache directory tags, see:" \
			"#	https://bford.info/cachedir/spec.html" \
			>$tagfile
	end
end