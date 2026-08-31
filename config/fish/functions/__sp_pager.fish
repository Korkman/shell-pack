function __sp_pager -d \
	'Invoke the configured pager'

	argparse 'line=' 'search=' 'prompt=' 'R/raw' 'clear-screen' -- $argv
	or return

	set -l filename $argv[1]

	if set -q _flag_line && ! string match -qr '^[1-9][0-9]*$' -- $_flag_line
		echo "Error: --line requires a positive integer argument" >&2
		return 2
	end

	set -l pager
	if set -q PAGER
		set pager $PAGER
	else if command -q less
		set pager less
	else if command -q more
		set pager more
	else
		set pager cat
		echo "Warning: No \$PAGER configured and no fallbacks found (less, more). Passing through as-is." >&2
	end

	set -l opts
	switch "$pager"
		# whitelist of pagers known to accept less-style options
		case "*less"
			if set -q _flag_raw
				set -a opts -R
			end
			if set -q _flag_clear_screen
				set -a opts --clear-screen
			end
			if set -q _flag_prompt
				set -a opts -P "$_flag_prompt"
				# force less to read the whole (piped) input upfront, so paging/searching
				# behaves consistently right away instead of lazily as more input arrives
				set -a opts +G +g
			end
			if set -q _flag_line
				set -a opts "+$_flag_line"g
			end
			if set -q _flag_search
				set -a opts +/"$_flag_search"
			end
		case "*ppage" "*grasp"
			if set -q _flag_line
				set -a opts --line=$_flag_line
			end
			if set -q _flag_search
				set -a opts --search="$_flag_search"
			end
			# -R/--raw and --clear-screen are no-ops here: ansi colors are always on and
			# fzf owns screen redraws; --prompt has no equivalent, so it is dropped
	end

	if set -q filename[1]
		$pager $opts "$filename"
	else
		$pager $opts
	end
end
