function __sp_pager -d \
	'Invoke the configured pager'
	if test -t 0
		echo "Error: __sp_pager expects input from a pipe or redirection, but stdin is a terminal." >&2
		return 1
	end
	
	if set -q PAGER
		if string match -qr '^less' -- $PAGER
			$PAGER $argv
		else
			$PAGER
		end
	else if command -q less
		less $argv
	else if command -q more
		more
	else
		cat
		echo "Warning: No \$PAGER configured and no fallbacks found (less, more). Passing through as-is." >&2
	end
end
