function rrg-in-file -d "rrg in file and focus on matching lines."
	#echo (string join '|' -- $argv)
	
	test "$argv" != ""
	and argparse -n rrg-in-file 't/truncate' 'f/file=' 'l/line=' 'h/help' 'p/rrg-preview=' -- $argv
	and not set -q _flag_help
	and set -q _flag_file
	or begin
		echo "\
Usage: rrg-in-file -f FILE [ --line N ] [ --truncate ] QUERY

Search for a regex in FILE with same parser as rrg. Show matching
lines with context.

   -f/--file FILE     File to parse. Use - for stdin.
   -l/--line          Jump to line N in file. Interactive with less.
   -t/--truncate      Truncate file before matching. Roughly limits
                      matches to one. Non-interactive.
   -p/--rrg-preview   Preview pane mode, pass result line for error
                      message display. Used by rrg.
   --help             Show this help
"
		if set -q _flag_help
			return 0
		else
			return 2
		end
	end
	
	set query "$argv"
	set -l extra_opts
	if set -q RG_EXTRA
		set extra_opts (string split ' ' -- $RG_EXTRA)
	end
	
	set startpoint 1
	set opt_linenumber "--line-number"
	set starting "start-with-cat"
	set ending "end-with-less-multi"
	if set -q _flag_line
		set ending "end-with-less-single"
	end

	if set -q _flag_truncate
		if ! set -q _flag_line
			echo "Error: --truncate requires --line"
			return 3
		end
		if [ "$_flag_line" = "ERROR" ]
			if set -q _flag_rrg_preview
				echo -- "(press ctrl-p to toggle pane)"
				echo -- "Error message:"
				echo
				echo -- (string replace --regex '^!//ERROR// ' '' -- "$_flag_rrg_preview")
			else
				echo "(line argument is 'ERROR', no preview)"
			end
			return 0
		end
		set startpoint (math "$_flag_line" - 3 )
		if [ "$startpoint" -lt 1 ]
			set startpoint 1
		end
		set opt_linenumber "--no-line-number"
		set starting "start-with-tail"
		set ending "end-with-tail"
		set opt_passthru "--passthru"
	end
	
	function start-with-cat --no-scope-shadowing
		# NOTE: using rg as a "clever cat" here so opening zipped results from rrg works
		rg --text --follow --search-zip --color=never -- "" "$_flag_file"
	end
	
	function start-with-tail --no-scope-shadowing
		# NOTE: using rg as a "clever cat" here so opening zipped results from rrg works
		rg --text --follow --search-zip --color=never -- "" "$_flag_file" | tail -n "+$startpoint" \
		# cut off file:
		| head -n 20
	end

	function end-with-less-single --no-scope-shadowing
		# show file with current line highlighted
		less \
		--clear-screen \
		"+/^$_flag_line:" \
		-j 3 \
		-R
	end

	function end-with-less-multi --no-scope-shadowing
		# show file with current line highlighted
		less \
		--clear-screen \
		"+/^[0-9]+:" \
		-j 3 \
		-R
	end

	function end-with-tail --no-scope-shadowing
		# re-add line numbers, emulating ripgrep + less style:
		awk \
		-v "i=$startpoint" \
		-v "l=$_flag_line" \
		# linenumber highlighted
		-v lh=(set_color -b ffff00; set_color black) \
		# linenumber normal
		-v ln=(set_color green) \
		# color reset
		-v cr=(set_color normal) \
		'BEGIN { OFS="" } { print (i == l ? lh : ln), i, (i == l ? ":" : "-"), cr, "", $0; i++ }'
	end
	
	# header
	if set -q _flag_line && set -q _flag_truncate
		if set -q _flag_rrg_preview
			echo -- "(press ctrl-p to toggle pane)"
		end
		echo -- "Results for '$query' $extra_opts"
		echo -- "at $_flag_file:$_flag_line"
		echo
	end

	# start outputting file at position $startpoint:
	$starting \
	# pipe to ripgrep:
	| rg \
	--no-config \
	--no-ignore \
	--no-heading \
	--auto-hybrid-regex \
	--ignore-case \
	--text \
	-C5 \
	$opt_passthru \
	$opt_linenumber \
	--context-separator "\n(…)\n" \
	--color always \
	$extra_opts \
	-e "$query" \
	# pipe to end function:
	| $ending
end
