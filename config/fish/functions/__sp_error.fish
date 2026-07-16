function __sp_error -d \
	'Display a slightly styled error message via stderr. Pass multiple args for multiline messages.'

	# if no args are given, print a stack trace
	if test (count $argv) -eq 0
		set -l stack (LC_ALL=C status stack-trace)
		set -l stack $stack[4..]
		__sp_error "Error was raised:" $stack
		return
	end
	
	# if more than one arg is given, create a nice vertical line for the indent
	set -l pipeindent ""
	if test (count $argv) -gt 1
		set pipeindent "│"
	end
	
	# wrap lines for the indent
	# split all arguments wider than $COLUMNS - 5
	set -l max_width (math (set -q COLUMNS; and echo $COLUMNS; or echo 80) - 5)
	set -l expanded_args
	for arg in $argv
		if test (string length -- $arg) -gt $max_width
			set -l lines (string split \n -- (echo $arg | fold -s -w $max_width))
			set -a expanded_args $lines
		else
			set -a expanded_args $arg
		end
	end
	set argv $expanded_args
	
	# capture all output to stderr
	begin
		set -l msg $argv[1]
		# it is legit to pass an empty string as first arg to hide the warnsign
		if test $msg != ""
			echo -n (set_color ff0)(__spt warnsign)(set_color normal)
			echo "$pipeindent $msg"
		end
		# all further args are indented lines
		for arg in $argv[2..]
			echo "  $pipeindent $arg"
		end
	end >&2
end
