function grasp -d \
	"Pipe live stream or file through fzf"
	
	set -l default_lines 10000
	set -l default_pager_lines 100000
	set -lx GRASP_HIST_FILE "$HOME/.local/share/shell-pack/fzf_grasp_history"

	argparse --stop-nonopt p/pager t/tail=? n/line-number -- $argv
	
	if ! test -e "$HOME/.local/share/shell-pack"
		mkdir -p "$HOME/.local/share/shell-pack"
	end
	
	
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
			echo "Alias ppage invokes grasp with --pager."
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
		echo 'alt-c:clear-query'
		echo 'alt-w:word-wrap alt-o:sort-best'
		echo 'alt-l:line-numbers'
		echo 'alt-up/dn:jump-selected'
		echo 'f2/f3/alt-p/-n:jump-match'
		echo 'alt-page-up/dn:begin/end'
		echo 'alt-f:(un)filter'
		echo 'alt-s/-S:print-/save-selected'
		echo 'alt-m/-M:print-/save-matched'
		echo 'alt-a:select-all alt-n:deselect-all'
		echo 'ctrl-p/-n:query-history'
		echo 'alt-y/dbl-clk:to-clipboard'
		echo (set_color bryellow)'*use solo keys when search hidden'(set_color normal)
	end | __sp_fzf_header
	
	# start off with generic defaults
	__sp_fzf_defaults --exact --compact
	
	# what command to use for repeatedly cat'ing the input
	set -l recat_cmd
	if set -q GRASP_PAGER
		set recat_cmd "cat {*f}"
	else
		set recat_cmd "if [ -x tac ]; then tac {*f}; else fishcall tac {*f}; fi"
	end

	# process line numbering with an extra tool in the pipe, save as $evalpipe
	set -l evalpipe
	set -l columns_margin 2
	if set -q _flag_line_number
		# increase columns_margin to accommodate line numbers when enabled, so `ppage man man` doesn't wrap
		set columns_margin 8
		set GRASP_LN 1
		if set -q GRASP_PAGER
			set evalpipe '__sp_linenumbers -w auto | $fzf_defaults'
		else
			set evalpipe '__sp_linenumbers -w 6 | $fzf_defaults'
		end
	else
		set evalpipe '$fzf_defaults'
	end
	
	# fzf toggle command for line numbers
	set -l linenumber_cmd
	if test "$GRASP_LN" = "1"
		# line numbers present, must be undone
		set linenumber_cmd 'fishcall eval "__sp_linenumbers --undo | GRASP_LN=0 ppage"'
	else
		# line numbers not preset, adds them via ripgrep
		set linenumber_cmd 'fishcall eval "__sp_linenumbers -w auto -t $FZF_TOTAL_COUNT | GRASP_LN=1 ppage"'
	end

	# fzf command for adding query history
	set -l write_history_cmd
	if test -e "$GRASP_HIST_FILE" && test ! -w "$GRASP_HIST_FILE"
		# in case of read-only filesystem, disable history
		set write_history_cmd ''
	else
		# fzf command to dedup and write history file
		set write_history_cmd '+execute-silent([ -z {q} ] && exit; [ ! -e "$GRASP_HIST_FILE" ] && last="" || last=$(tail -n1 "$GRASP_HIST_FILE"); [ "$last" = {q} ] && exit; echo {q} >> "$GRASP_HIST_FILE")'
	end

	# these keys can be used with no modifier key in pager mode (enter)
	set -l pager_mode_keys 'n,N,p,:,/,w,t,f,q,space,g,G,s,S,m,M,c,l'
	# main fzf keybinds
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
		'f3,n:down-match+track-current,f2,p,N:up-match+track-current,' \
		'tab:toggle+down+track-current,' \
		'alt-l,l:become('$recat_cmd' | '$linenumber_cmd'),' \
		'alt-f,f:toggle-raw,' \
		'alt-q,q:abort,' \
		'alt-.,ctrl-r:prev-history,alt-,:next-history,' \
		'enter,esc:hide-input+rebind('$pager_mode_keys')'$write_history_cmd',' \
		':,/,space:show-input+unbind('$pager_mode_keys'),' \
		'alt-c,c:show-input+clear-query+hide-input+rebind('$pager_mode_keys'),' \
		'alt-y,double-click:execute(printf "\033]52;c;%s\a" $(for i in {+}; do echo "$i"; done | base64 | tr -d "\n"))'
	)
	# add keybinds and more to list of args
	set -a fzf_defaults --highlight-line --wrap-word --multi --exact --ansi --no-sort --tail=$GRASP_TAIL --bind "$fzf_binds" --height=-1 --history "$GRASP_HIST_FILE"

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
	
	if test ! -t 1
		# STDOUT is not a terminal! Someone is using us as a pipe
		if set -q GRASP_PAGER
			set evalpipe __sp_grasp_fzf_is_cat
		end
	end

	set -l fzf_status
	if test ! -t 0
		# read from stdin which is not a terminal
		set -l input_label (__spt fzf_title bold)" grasping "(__spt prompt_fg)"STDIN"(set_color normal)" "(set_color normal)
		set -a fzf_defaults --input-label "$input_label"
		eval $evalpipe
		set fzf_status $status
	else
		if test (count $argv) -eq 1 && test -e $argv[1]
			# read tail from file
			if set -q GRASP_PAGER
				set cmd tail -n $GRASP_TAIL -- $argv[1]
			else
				# in stream mode, follow the file
				set cmd tail -fn $GRASP_TAIL -- $argv[1]
			end
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
		# add nice title
		set -l input_label (__spt fzf_title bold)" grasping "(__spt prompt_fg)"$grasptitle"(set_color normal)" "(set_color normal)
		set -a fzf_defaults --input-label "$input_label"

		# leave cmd execution (and killing of it) to fzf
		set -x FZF_DEFAULT_COMMAND "$cmd"
		eval $evalpipe
		set fzf_status $status
	end
	if status is-interactive && test $fzf_status -eq 50
		commandline 'cat '(string escape -- $GRASP_DUMPFILE)' '
	end
	
	return 0
end

function __sp_grasp_fzf_is_cat
	# discarding all fzf arguments, we become 'cat'
	cat
end