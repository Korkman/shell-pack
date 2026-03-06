function grasp -d \
	"Pipe live stream or file through fzf"
	
	argparse --stop-nonopt t/tail=? -- $argv
	
	if set -q _flag_tail
		set GRASP_TAIL $_flag_tail
	else if not set -q GRASP_TAIL
		set GRASP_TAIL 10000
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
	end | __sp_fzf_header
	__sp_fzf_defaults "grasping "(__spt prompt_fg)"$cmd"(set_color normal)
	
	set -l fzf_binds (printf %s \
		'f1,alt-h:execute(fishcall cheat --fzf-query),' \
		'alt-w:toggle-wrap-word,' \
		'alt-t:toggle-track,' \
		'alt-s:execute-silent(cat {+f} > $HOME/grasp-saved.txt)+become(printf %s\\\\n "Saved to $HOME/grasp-saved.txt"),' \
		'alt-m:select-all+execute-silent(cat {+f} > $HOME/grasp-saved.txt)+become(printf %s\\\\n "Saved to $HOME/grasp-saved.txt"),' \
		'alt-a:select-all,' \
		'alt-n:deselect-all,' \
		'alt-o:toggle-sort'
	)
	
	set -a fzf_defaults --ansi --tac --no-sort --tail=$GRASP_TAIL --no-reverse --multi --bind "$fzf_binds"
	set -p fzf_defaults fzf

	if test ! -t 0
		$fzf_defaults
	else
		if test -e $argv[1]
			set cmd tail -n $GRASP_TAIL -- $argv[1]
		else
			set cmd $argv
		end
		# cut off /dev/tty from $cmd so it doesn't interfere with fzf's input (ssh journalctl crashes otherwise)
		$cmd < /dev/null | $fzf_defaults
	end
	return 0
end
