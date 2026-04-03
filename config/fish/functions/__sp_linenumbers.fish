function __sp_linenumbers -d \
	"Add line numbers to input. Pass --total, --width and --undo to control behavior."
	argparse u/undo w/width= t/total= -- $argv
	
	if set -q _flag_undo
		cat | string replace --regex "^.*?:" ""
		return
	end
	
	if ! set -q _flag_total && test "$_flag_width" = "auto"
		# count lines in tmp file to determine width
		set -l tmpfile (mktemp --tmpdir __sp_linenumbers.XXXXXX)
		cat > $tmpfile
		wc -l < $tmpfile | string match -q --regex "^\s*(?<_flag_total>[0-9]+)"
		cat $tmpfile | __sp_linenumbers --width=auto --total=$_flag_total
		rm $tmpfile
		return
	end
	
	if test "$_flag_width" = "auto"
		set _flag_width (string length -- $_flag_total)
	else if ! set -q _flag_width
		set _flag_width 6
	end
	
	# add line numbers with padding using awk
	awk -v width=$_flag_width '{printf "%s%*d%s:%s\n", "'(__spt linenumber)'", width, NR, "'(set_color normal)'", $0}'
end
