function grasp -d \
	"Pipe live stream or file through fzf"
	
	argparse --stop-nonopt t/tail=? -- $argv
	
	if set -q _flag_tail
		set GRASP_TAIL $_flag_tail
	else if not set -q GRASP_TAIL
		set GRASP_TAIL 10000
	end

	set -x GRASP_DUMPFILE "$HOME/grasp-saved.txt"
	# escaping gets difficult when quotes or backslashes are in $HOME. workaround for now.
	if string match -q --regex -- '(\\\\|")' $GRASP_DUMPFILE
		echo "Warning: \$HOME has backslashes or quotes" >&2
		set -x GRASP_DUMPFILE "/tmp/grasp-saved.txt"
	end
	
	if test (count $argv) -eq 0 && test -t 0
		echo "Usage: grasp [...OPTIONS] COMMAND [...ARGS]" >&2
		echo "       grasp [...OPTIONS] FILE" >&2
		echo "       cat | grasp [...OPTIONS]" >&2
		echo >&2
		echo "Options:" >&2
		echo "  -t, --tail=N    Max number of lines in memory (default: 10000)" >&2
		return 1
	end
	
	if test (count $argv) -gt 0 && test ! -t 0
		echo "Error: must have controlling terminal when passing command arguments." >&2
		return 2
	end
	
	begin
		echo 'esc:cancel enter:done f1:help-syntax'
		echo 'alt-w:word-wrap alt-t:track alt-o:toggle-sort'
		echo 'alt-s:save-selected alt-m:save-matched'
		echo 'alt-a:select-all alt-n:deselect-all'
		echo 'alt-up/dn:jump-selected'
		echo 'shift-up/dn:page alt-shift-up/dn:begin/end'
		echo 'alt-r:reduce-to-matched'
	end | __sp_fzf_header
	__sp_fzf_defaults
	
	set -l fzf_binds (printf %s \
		'f1,alt-h:execute(fishcall cheat --fzf-query),' \
		'alt-w:toggle-wrap-word,' \
		'alt-t:toggle-track-current,' \
		'alt-s:execute-silent(cat {+f} > "$GRASP_DUMPFILE")+become(printf %s\\\\n "Saved to $GRASP_DUMPFILE"; exit 50),' \
		'alt-m:select-all+execute-silent(cat {+f} > "$GRASP_DUMPFILE")+become(printf %s\\\\n "Saved to $GRASP_DUMPFILE"; exit 50),' \
		'alt-a:select-all,' \
		'alt-n:deselect-all,' \
		'alt-o:toggle-sort,' \
		'shift-up:page-up+track-current,shift-down:page-down+track-current,' \
		'alt-shift-up,shift-page-up:pos(-1)+track-current,alt-shift-down,shift-page-down:pos(0)+track-current,' \
		'up:up+track-current,down:down+track-current,' \
		'page-up:page-up+track-current,page-down:page-down+track-current,' \
		'alt-up:up-selected+track-current,alt-down:down-selected+track-current,' \
		'left-click:track-current,right-click:select+track-current,' \
		'tab:select+down+track-current,' \
		'alt-r:reload(cat {*f})'
	)
	
	set -a fzf_defaults --ansi --tac --no-sort --tail=$GRASP_TAIL --no-reverse --multi --bind "$fzf_binds" --height=-1
	set -p fzf_defaults fzf

	set -l fzf_status
	if test ! -t 0
		set -l input_label (__spt fzf_title bold)" grasping "(__spt prompt_fg)"STDIN"(set_color normal)" "(set_color normal)
		set -a fzf_defaults --input-label "$input_label"
		$fzf_defaults
		set fzf_status $status
	else
		if test (count $argv) -eq 1 && test -e $argv[1]
			set cmd tail -n $GRASP_TAIL -- $argv[1]
		else
			set cmd $argv
		end
		set -l input_label (__spt fzf_title bold)" grasping "(__spt prompt_fg)"$cmd"(set_color normal)" "(set_color normal)
		set -a fzf_defaults --input-label "$input_label"
		# cut off /dev/tty from $cmd so it doesn't interfere with fzf's input (ssh journalctl crashes otherwise)
		$cmd < /dev/null | $fzf_defaults
		set fzf_status $status
	end
	if test $fzf_status -eq 50
		commandline (string escape -- $GRASP_DUMPFILE)
		commandline --cursor 0
	end
	
	return 0
end
