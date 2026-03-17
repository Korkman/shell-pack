function grasp -d \
	"Pipe live stream or file through fzf"
	
	argparse --stop-nonopt p/pager n/tail=? -- $argv
	
	set -l default_lines 10000
	set -l default_pager_lines 100000
	
	
	if set -q _flag_pager
		set GRASP_PAGER yes
		if ! set -q _flag_tail
			set _flag_tail $default_pager_lines
		end
	end
	
	if set -q _flag_tail
		set GRASP_TAIL $_flag_tail
	else if not set -q GRASP_TAIL
		set GRASP_TAIL $default_lines
	end

	set -x GRASP_DUMPFILE "$HOME/grasp-saved.txt"
	# escaping gets difficult when quotes or backslashes are in $HOME. workaround for now.
	if string match -q --regex -- '(\\\\|")' $GRASP_DUMPFILE
		echo "Warning: \$HOME has backslashes or quotes" >&2
		set -x GRASP_DUMPFILE "/tmp/grasp-saved.txt"
	end
	
	if test (count $argv) -eq 0 && test -t 0
		begin
			echo "Usage: grasp [...OPTIONS] COMMAND [...ARGS]"
			echo "       grasp [...OPTIONS] FILE"
			echo "       cat | grasp [...OPTIONS]"
			echo
			echo "COMMAND will only be executed if it is not a FILE. Otherwise, FILE will be tailed."
			echo 
			echo "Options:"
			echo "  -nN, --tail=N   Max number of lines in memory (default: $default_lines)"
			echo "  -p, --pager     'pager' mode: behave more like a pager with search (raises tail default to $default_pager_lines)"
			echo
			echo "Alias graspp invokes grasp with --pager."
		end >&2
		return 1
	end
	
	if test (count $argv) -gt 0 && test ! -t 0
		echo "Error: must have controlling terminal when passing command arguments." >&2
		return 2
	end
	
	begin
		echo 'slash/spc:show-search esc:hide-search'
		echo 'alt-q:exit f1:help-syntax'
		echo 'alt-w:word-wrap alt-t:track alt-o:sort-best'
		echo 'alt-up/dn:jump-selected'
		echo 'f6/f7/ctrl-p/-n:jump-match'
		echo 'alt-page-up/dn:begin/end'
		echo 'alt-r:reload-matched'
		echo 'alt-f:(un)filter'
		echo 'alt-s/-S:print-/save-selected'
		echo 'alt-m/-M:print-/save-matched'
		echo 'alt-a:select-all alt-n:deselect-all'
		echo 'Hide search = no modifier'
	end | __sp_fzf_header
	
	__sp_fzf_defaults --exact --compact
	
	# these keys can be used with no modifier key in pager mode (enter)
	set -l pager_mode_keys 'n,N,p,:,/,w,t,r,f,q,space,g,G,s,S,m,M'
	
	set -l fzf_binds (printf %s \
		'f1,alt-h:execute(fishcall cheat --fzf-query),' \
		'alt-w,w:toggle-wrap-word,' \
		'alt-t,t:toggle-track-current,' \
		'alt-S,S:execute-silent(cat {+f} > "$GRASP_DUMPFILE")+become(printf %s\\\\n "Saved to $GRASP_DUMPFILE"; exit 50),' \
		'alt-M,M:select-all+execute-silent(cat {+f} > "$GRASP_DUMPFILE")+become(printf %s\\\\n "Saved to $GRASP_DUMPFILE"; exit 50),' \
		'alt-s,s:accept,' \
		'alt-m,m:disable-raw+select-all+accept,' \
		'alt-a:select-all,' \
		'alt-n:deselect-all,' \
		'alt-o:toggle-sort,' \
		'shift-up:page-up+track-current,shift-down:page-down+track-current,' \
		'alt-shift-up,shift-page-up,alt-page-up,g:first+track-current,alt-shift-down,shift-page-down,alt-page-down,G:last+track-current,' \
		'up:up+track-current,down:down+track-current,' \
		'page-up:page-up+track-current,page-down:page-down+track-current,' \
		'alt-up:up-selected+track-current,alt-down:down-selected+track-current,' \
		'left-click:track-current,right-click:select+track-current,' \
		'ctrl-n,f3,f7,n:down-match+track-current,ctrl-p,f6,p,N:up-match+track-current,' \
		'tab:toggle+down+track-current,' \
		'alt-r,r:select-all+reload(fishcall tac {+f}),' \
		'alt-f,f:toggle-raw,' \
		'alt-q,q:abort,' \
		'enter,esc:hide-input+rebind('$pager_mode_keys'),' \
		':,/,space:show-input+unbind('$pager_mode_keys'),' \
		'alt-c:kill-line+show-input+unbind('$pager_mode_keys')'
	)
	
	set -a fzf_defaults --highlight-line --wrap-word --multi --exact --ansi --no-sort --tail=$GRASP_TAIL --bind "$fzf_binds" --height=-1

	# start in compact mode with invisible search (q exits)
	set -a fzf_defaults --bind 'start:unbind(result)+trigger(esc)+hide-header,change:rebind(result)'
	
	if set -q GRASP_PAGER
		# setup as pager: display unmatched lines, match results from current position downwards
		set -a fzf_defaults --layout=reverse-list --raw --bind 'result:up+down-match,zero:down'
		# when used as pager, chances are we get lines formatted for full $COLUMNS as STDIN, so we adjust style to display full width - no compromise
		set -a fzf_defaults --no-scrollbar --pointer="" --marker=""
	else
		# in stream mode, results keep flowing in, so don't bind 'result'. instead use --tac to follow the flow.
		set -a fzf_defaults --tac --no-reverse
		# swap first / last, stop tracking on first
		set -a fzf_defaults --bind 'alt-shift-up,shift-page-up,alt-page-up,g:last+track-current,alt-shift-down,shift-page-down,alt-page-down,G:first'
		# start in compact mode with visible search
		#set -a fzf_defaults --bind 'start:trigger(space)+hide-header'
	end

	set -p fzf_defaults fzf

	set -l fzf_status
	if test ! -t 0
		# read form stdin which is not a terminal
		set -l input_label (__spt fzf_title bold)" grasping "(__spt prompt_fg)"STDIN"(set_color normal)" "(set_color normal)
		set -a fzf_defaults --input-label "$input_label"
		$fzf_defaults
		set fzf_status $status
	else
		if test (count $argv) -eq 1 && test -e $argv[1]
			# read tail from file
			set cmd tail -fn $GRASP_TAIL -- $argv[1]
			set grasptitle $argv[1]
		else if type -q $argv[1]
			# run passed command
			set cmd $argv
			set grasptitle $cmd
		else
			echo "Neither command nor file: '"$argv[1]"'" >&2
			return 2
		end
		# restrict grasptitle to 80% of terminal width
		fish_prompt_shorten_string grasptitle 80
		
		set -l input_label (__spt fzf_title bold)" grasping "(__spt prompt_fg)"$grasptitle"(set_color normal)" "(set_color normal)
		set -a fzf_defaults --input-label "$input_label"
		# `< /dev/null` - cut off /dev/tty from $cmd so it doesn't interfere with fzf's input (ssh journalctl crashes otherwise)
		# `COLUMNS=...` - reduce terminal width for $cmd so it wraps nicely within fzf's padding
		set -l fifo_info (COLUMNS=(math $COLUMNS-2) __sp_fifo_helper $cmd < /dev/null)
		or return 2
		set -l fifo_pid $fifo_info[1]
		set -l fifo_path $fifo_info[2]
		if test "" = "$fifo_pid" || ! test -e "$fifo_path"
			echo "Failed to create FIFO at $fifo_path" >&2
			return 3
		end
		set -l fifo_pid_fp (__sp_pid_fingerprint $fifo_pid)
		$fzf_defaults < "$fifo_path"
		set fzf_status $status
		__sp_pid_fingerprint_kill $fifo_pid $fifo_pid_fp
		rm -f "$fifo_path"
	end
	if status is-interactive && test $fzf_status -eq 50
		commandline (string escape -- $GRASP_DUMPFILE)
		commandline --cursor 0
	end
	
	return 0
end
