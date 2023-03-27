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
	set file_basename (basename "$_flag_file")
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
	
	function start-with-cat --no-scope-shadowing -d \
		'Pipe entire input file to rg'
		# NOTE: using rg as a "clever cat" here so opening zipped results from rrg works
		rg --text --follow --search-zip --color=never -- "" "$_flag_file"
	end
	
	function start-with-tail --no-scope-shadowing -d \
		'Pipe only an excerpt from the input file'
		# NOTE: using rg as a "clever cat" here so opening zipped results from rrg works
		rg --text --follow --search-zip --color=never -- "" "$_flag_file" | tail -n "+$startpoint" \
		# cut off file:
		| head -n 20
	end

	function end-with-less-single --no-scope-shadowing -d \
		'Present with less, highlighting a specific line'
		
		set -lx LESSHISTFILE '-'
		less \
		--clear-screen \
		'+/^'"$_flag_line"':' \
		"+/^[0-9]+:" \
		-j 3 \
		-R \
		'-Ps '(rrg-in-file-desc)' | less - q to quit, h for help $'
	end

	function end-with-less-multi --no-scope-shadowing -d \
		'Present with less, highlighting all line numbers followed by ":"'
		
		set -lx LESSHISTFILE '-'
		less \
		--clear-screen \
		"+/^[0-9]+:" \
		-j 3 \
		-R \
		'-Ps '(rrg-in-file-desc)' | less - q to quit, h for help $'
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
		if set -q _flag_rrg_preview
			echo (set_color -b ff00ff; set_color black)' End of match preview with context | ctrl-p to hide pane '(set_color normal)
		end
	end
	
	function rrg-in-file-desc --no-scope-shadowing
		switch "$starting"
			case 'start-with-cat'
				echo -n "n = next, N = prev match - all matches shown"
			case 'start-with-tail'
				echo -n "showing only one match"
			case '*'
				echo -n "Unknown input"
		end

		#switch "$ending"
		#	case 'end-with-tail'
		#		echo -n "non-interactive"
		#	case 'end-with-less-single'
		#	case 'end-with-less-multi'
		#		echo -n "n = next, N = prev match"
		#	case '*'
		#		echo -n "unknown output"
		#end
	end

	# header
	if set -q _flag_line && set -q _flag_truncate
		echo -- "Single result with context for '$query' $extra_opts"
		echo -- "in $_flag_file"
		echo -- "line $_flag_line"
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
