function cachedir-untag --description "Remove a CACHEDIR.TAG file from the specified directory"
	argparse 'h/help' -- $argv
	or return

	if set -q _flag_help
		echo "Usage: cachedir-untag [DIRECTORY...]"
		echo "Removes the CACHEDIR.TAG file from each specified directory (default: current directory)."
		return 0
	end

	set -l dirs $argv
	if test (count $dirs) -eq 0
		set dirs .
	end

	for dir in $dirs
		set -l tagfile $dir/CACHEDIR.TAG
		if not test -f $tagfile
			echo "cachedir-untag: no CACHEDIR.TAG in: $dir" >&2
			return 0
		end

		if not string match -q "Signature: 8a477f597d28d172789f06886806bc55" (head -n 1 $tagfile)
			echo "cachedir-untag: invalid signature in: $tagfile" >&2
			return 1
		end

		rm $tagfile
	end
end
