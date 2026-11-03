function __sp_pager -d \
	'Invoke the configured pager, adapt flags if possible'
	
	argparse --stop-nonopt 'F/quit-if-one-screen' 'get-bin' 'man' 'line=' 'search=' 'P/prompt=' 'R/raw' 'clear-screen' 'syntax=?' 'line-number' -- $argv
	or return
	
	set -l filename $argv[1]
	
	if set -q _flag_line && ! string match -qr '^[1-9][0-9]*$' -- $_flag_line
		echo "Error: --line requires a positive integer argument" >&2
		return 2
	end
	
	# unwrap proxied variables
	if test -n "$TRUE_PAGER"
		set -gx PAGER "$TRUE_PAGER"
		set -e TRUE_PAGER
	end
	# discard invalid values
	if test "$PAGER" = "__sp_mc_pager_proxy"
		set -ge PAGER
	end
	
	set -l pager_cmd
	# allow MANPAGER if --man was passed
	if set -q _flag_man && test -n "$MANPAGER"
		set pager_cmd "$MANPAGER"
	else
		set pager_cmd "$PAGER"
	end
	# $PAGER may carry arguments, e.g. "less -S"
	set pager_cmd (string split -n -- ' ' (string trim -- "$pager_cmd"))
	if ! type -q -- "$pager_cmd[1]"
		set pager_cmd
	end
	if not set -q pager_cmd[1]
		if type -q ppage
			set pager_cmd ppage
		else if command -q less
			set pager_cmd less
		else if command -q more
			set pager_cmd more
		else
			set pager_cmd cat
			echo "Warning: No \$PAGER configured and no fallbacks found (less, more). Passing through as-is." >&2
		end
	end
	set -l pager_bin $pager_cmd[1]
	set -l pager_args $pager_cmd[2..-1]
	
	if set -q _flag_get_bin
		echo "$pager_bin"
		return
	end
	
	# name tab after pager
	__sp_tabtitle_suggestion (path basename "$pager_bin")
	
	set -l opts
	switch "$pager_bin"
		# whitelist of pagers known to accept less-style options
		case "*less"
			if set -q _flag_raw
				set -a opts -R
			end
			if set -q _flag_clear_screen
				set -a opts --clear-screen
			end
			if set -q _flag_quit_if_one_screen
				set -a opts -F
			end
			if set -q _flag_prompt && $__cap_less_has_prompt
				set -a opts -P "$_flag_prompt"
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
			if set -q _flag_syntax
				set -a opts --syntax="$_flag_syntax"
			end
			if set -q _flag_line_number
				set -a opts --line-number
			end
			if set -q _flag_quit_if_one_screen
				set -a opts --quit-if-one-screen
			end
			if set -q _flag_prompt
				set -a opts --prompt "$_flag_prompt"
			end
			# -R/--raw and --clear-screen are no-ops here: ansi colors are always on and
			# fzf owns screen redraws
	end
	
	if set -q filename[1]
		$pager_bin $pager_args $opts $argv
	else
		$pager_bin $pager_args $opts
	end
	set -l pager_status $status
	
	__sp_tabtitle_suggestion --restore
	return $pager_status
end
