function grasp -d \
"Pipe live stream or page file through 'bat' and 'fzf' for searching and filtering."
	set -l default_lines 10000
	set -l default_lines_pager 500000
	set -l default_bat_max_size 1048576
	set -x GRASP_DUMPFILE "$HOME/grasp-saved.txt"
	# escaping gets difficult when quotes or backslashes are in $HOME. workaround for now.
	if string match -q --regex -- '(\\\\|")' $GRASP_DUMPFILE
		echo "Warning: \$HOME has backslashes or quotes" >&2
		set -x GRASP_DUMPFILE "/tmp/grasp-saved.txt"
	end
	
	begin
		echo (set_color brwhite --bold)"  PAGING"(set_color normal)
		echo "  up / down            Move line selection up/down"
		echo "  pgup/-dn             Page up/down"
		echo "                       (also: shift-up/-down)"
		echo "  g, alt-g             Jump to first line"
		echo "                       (also: alt-shift-up, shift-page-up, alt-page-up)"
		echo "  G, alt-G             Jump to last line (and follow new input)"
		echo "                       (also: alt-shift-down, shift-page-down, alt-page-down)"
		echo "  l, alt-l, :          Prompt for a line number to jump to"
		echo "                       (also: esc, f10)"
		echo "  w, alt-w             Toggle word-wrap"
		echo "  t, alt-t             Toggle tracking of current line on new input"
		echo "  ctrl-r, f5           Reload content (when FILE or COMMAND was passed)"
		echo "  alt-e, f4            Edit file in \$EDITOR (when FILE was passed)"
		echo "  q, alt-q             Quit"
		echo
		echo (set_color brwhite --bold)"  MATCHING"(set_color normal)
		echo "  space, /             New fzf search (see also FZF QUERY SYNTAX below)"
		echo "                       (also: ctrl-f)"
		echo "  +                    Edit search input"
		echo "  alt-up/-down         Recall search history"
		echo "                       (also: alt-., alt-,)"
		echo "  enter                Hide search input"
		echo "  n, alt-n             Jump to next match"
		echo "                       (also: f3, ctrl-g)"
		echo "  p, N, alt-N          Jump to previous match"
		echo "                       (also: f2, alt-p)"
		echo "  esc                  Clear query, hide search box"
		echo "  f, alt-f             Toggle filter showing only matched lines"
		echo "  o, alt-o             Toggle sort best up (requires filter)"
		echo "  m, alt-m             Print all matched (filtered) line(s) and exit"
		echo
		echo (set_color brwhite --bold)"  SELECTING"(set_color normal)
		echo "  alt-a                Select all lines"
		echo "  alt-x                Deselect all lines"
		echo "  tab                  Toggle selection of current line, move down"
		echo "  s, alt-s             Print selected line(s) and exit"
		echo "  S, alt-S             Save selected line(s) to $GRASP_DUMPFILE"
		echo "  M, alt-M             Select and save all matched lines to $GRASP_DUMPFILE"
		echo "  alt-up/-down         Jump between selected lines"
		echo "  alt-y, double-click  Copy selected/current line(s) to clipboard"
		echo 
		echo (set_color brwhite --bold)"  OTHER"(set_color normal)
		echo "  f1, h, alt-h            Show keybinds"
		echo
		for line in (PAGER=cat __sp_cheat_fzf_query)
			echo "  $line"
		end
		echo
	end | read -z -l usage_keybinds

	begin
		echo -e (functions -vD (status current-function))[5]
		echo
		echo "Usage: grasp [...OPTIONS] COMMAND [...ARGS]"
		echo "       grasp [...OPTIONS] FILE"
		echo "       cat | grasp [...OPTIONS]"
		echo " Shortcut for --pager"
		echo "       ppage [...OPTIONS] FILE"
		echo
		echo "COMMAND will only be executed if it is not a FILE. Otherwise, FILE will be tailed."
		echo
		echo "Limited to $default_lines lines by default (not applied when --pager)."
		echo
		echo "A dynamic memory limit is in place which allows at max 10% of available memory to be consumed."
		echo
		echo "Options:"
		echo
		echo "  --tail=[COUNT], -t[COUNT]"
		echo "      Change line limit to COUNT.."
		echo
		echo "  --line-number, -n"
		echo "      Add line numbers."
		echo
		echo "  --line=N, -lN"
		echo "      Jump to line N on startup."
		echo
		echo "  --pager, -p"
		echo "      Use as pager. Starts at the top."
		echo "      'ppage' is a shorthand for this."
		echo
		echo "  --syntax[=LANGUAGE]"
		echo "      Force bat syntax highlighting, ignoring the size threshold and stream-mode skip."
		echo "      Optionally pass LANGUAGE to bat's -l flag (e.g. --syntax=json)."
		echo
		echo "  --no-syntax"
		echo "      Disable bat syntax highlighting."
		echo
		echo "  --quit-if-one-screen, -F"
		echo "      Output content without pager when it fits one screen"
		echo
		echo "  --search=QUERY"
		echo "      Pre-fill the search box with QUERY on startup."
		echo
		echo "  --prompt=PROMPT"
		echo "      Display PROMPT in status line."
		echo
		echo "  --cmd"
		echo "      Passed argument is strictly a command"
		echo
		echo "  --file"
		echo "      Passed argument is strictly a file"
		echo 
		echo "Keybinds:"
		echo
		echo $usage_keybinds
		echo
	end | read -z -l usage
	
	set -lx GRASP_HIST_FILE "$HOME/.local/share/shell-pack/fzf_grasp_history"
	if not set -q GRASP_JUMP_FILE
		# only generate once per fzf session: callback invocations (execute/transform) are separate
		# processes and must inherit the same path, not regenerate their own
		set -x GRASP_JUMP_FILE (__sp_mkuniq --xdg-runtime --dry-run grasp-jump)
	end

	set -l argv_copy $argv
	argparse --stop-nonopt 'P/prompt=' cmd file F/quit-if-one-screen p/pager 't/tail=?' n/line-number 'l/line=' 'syntax=?' no-syntax 'search=' 'fzf-callback=' help -- $argv
	or begin
		echo "grasp --help for usage"
		return 1
	end >&2
	set -l self grasp
	if set -q _flag_pager
		set self ppage
	end

	# these keys are only bound while the search input is hidden
	set -l pager_mode_keys 'n,N,p,:,/,w,t,f,q,space,g,G,s,S,m,M,c,l,b,r,+,a,x,o,h'
	set -x GRASP_PAGER_MODE_KEYS $pager_mode_keys
	
	if set -q _flag_fzf_callback
		# backwards compatible argument converter 2026-09-23
		set _flag_fzf_callback (string replace -r -- "^__sp_grasp_callback_" "" "$_flag_fzf_callback")
		eval "__sp_grasp_callback_$_flag_fzf_callback"
		return
	end
	
	if set -q _flag_help
		echo $usage
		return 0
	end >&2
	
	if set -q _flag_line && ! string match -qr '^[1-9][0-9]*$' -- $_flag_line
		echo "Error: --line requires a positive integer argument" >&2
		return 2
	end
	
	if ! test -e "$HOME/.local/share/shell-pack"
		mkdir -p "$HOME/.local/share/shell-pack"
	end
	
	
	if set -q _flag_pager
		set -x GRASP_PAGER yes
	else
		set -e GRASP_PAGER
	end
	
	if set -q _flag_tail
		set GRASP_TAIL $_flag_tail
	else if not set -q GRASP_TAIL
		if set -q GRASP_PAGER
			set GRASP_TAIL $default_lines_pager
		else
			set GRASP_TAIL $default_lines
		end
	end
	
	# above this many bytes, skip bat (no syntax highlighting) for a file
	if not set -q GRASP_BAT_MAX_SIZE
		set GRASP_BAT_MAX_SIZE $default_bat_max_size
	end
	
	if not set -q GRASP_MAX_FZF_RSS_KB
		set -l mem_available_kb (__sp_mem_available)
		and set -x GRASP_MAX_FZF_RSS_KB (math -s0 "$mem_available_kb * 0.1")
	end

	if test (count $argv) -eq 0 && test -t 0
		echo $usage >&2
		return 1
	end
	
	if set -q _flag_quit_if_one_screen
		# quit-if-one-screen is complex:
		#
		# - grasp can decompress files on the fly or apply lesspipe, so we need to
		#   use grasp as input generator and at the same time as output formatter.
		#   so we split off post-processing args and use grasp twice in the pipe.
		#
		# - limitation: since the passed FILE or COMMAND is transformed into
		#   STDIN, extra functionality like reload and edit does not apply
		
		# reparse original argv from copy and strip --quit-if-one-screen
		set argv (string match --invert --entire --regex -- '^(--quit-if-one-screen|-F)$' $argv_copy)
		set -l postprocess_args
		if set -q _flag_tail
			# tail processing in post ensures syntax highlighting stays intact
			set -a postprocess_args --tail=$_flag_tail
		end
		if set -q _flag_pager
			set -a postprocess_args --pager
		end
		if set -q _flag_line
			set -a postprocess_args --line=$_flag_line
		end
		if set -q _flag_search
			set -a postprocess_args --search=$_flag_search
		end
		# syntax highlighting is done in pre-processing, so we can skip it in post
		set -a postprocess_args --no-syntax
		# fishcall: to get unbuffered parallel processing, we need to force spawning a subprocess
		fishcall grasp $argv | __sp_grasp_one_screen_lead $postprocess_args
		return
	end
	
	# start off with generic defaults
	__sp_fzf_defaults --exact --compact
	
	if set -q _flag_line_number
		# reduce $COLUMS to accommodate line numbers when enabled, so `ppage man man` doesn't wrap
		set -x COLUMNS (math $COLUMNS - 8)
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

	# callback handler, may loop back into this file (see __sp_grasp_callback below)
	set -l callback_cmd '__sp_grasp_callback'
	
	# main fzf keybinds
	set -l fzf_binds (printf %s \
		'f1,alt-h,h:execute('$callback_cmd' help),' \
		'alt-w,w:toggle-wrap-word,' \
		'alt-t,t:toggle-track-current,' \
		'alt-S,S:execute-silent(cat {+f} > "$GRASP_DUMPFILE")+become(printf %s\\\\n "Saved to $GRASP_DUMPFILE"; exit 50),' \
		'alt-M,M:select-all+execute-silent(cat {+f} > "$GRASP_DUMPFILE")+become(printf %s\\\\n "Saved to $GRASP_DUMPFILE"; exit 50),' \
		'alt-s,s:accept,' \
		'alt-m,m:disable-raw+select-all+accept,' \
		'alt-a,a:select-all,' \
		'alt-x,x:deselect-all,' \
		'alt-o,o:disable-raw+toggle-sort,' \
		'shift-up:page-up+track-current,shift-down:page-down+track-current,' \
		'alt-shift-up,shift-page-up,alt-page-up,g,alt-g:first+track-current,' \
		'alt-shift-down,shift-page-down,alt-page-down,G,alt-G:last+track-current,' \
		'up:up+track-current,down:down+track-current,' \
		'page-up:page-up+track-current,page-down:page-down+track-current,' \
		'alt-up:up-selected+track-current,alt-down:down-selected+track-current,' \
		'left-click:track-current,right-click:select+track-current,' \
		'alt-N,alt-p,f2,p,N:up-match+track-current,' \
		'alt-n,f3,n,ctrl-g:down-match+track-current,' \
		':,alt-l,l:execute('$callback_cmd' line_jump_read)+clear-screen+transform('$callback_cmd' line_jump_apply),' \
		'tab:toggle+down+track-current,' \
		'alt-f,f:toggle-raw,' \
		'alt-q,q,f10:abort,' \
		'alt-up,alt-.:prev-history,' \
		'alt-down,alt-,:next-history,' \
		'esc:transform('$callback_cmd' escape),' \
		'enter:show-header+hide-input+rebind('$pager_mode_keys')'$write_history_cmd',' \
		'/,space,ctrl-f,f7:hide-header+show-input+clear-query+unbind('$pager_mode_keys'),' \
		'+:hide-header+show-input+unbind('$pager_mode_keys'),' \
		'alt-y,double-click:execute(printf "\033]52;c;%s\a" $(for i in {+}; do echo "$i"; done | base64 | tr -d "\n"))' \
	)
	
	# add keybinds and more to list of args
	set -a fzf_defaults --highlight-line \
		--multi --exact --ansi \
		--no-sort --bind "$fzf_binds" \
		--history "$GRASP_HIST_FILE" \
		--height=100%
	# adaptive height options removed as they hang indefinitely with small, open stdin (tail -n10 -f /etc/services)
	
	if not set -q GRASP_PAGER || set -q _flag_tail
		# pager mode uses tail cmd
		set -a fzf_defaults --tail=$GRASP_TAIL
	end
	
	# start in compact mode with invisible search (q exits), unless a query was pre-filled
	set -l start_bind 'start:trigger(esc)'
	if set -q _flag_search
		set -a fzf_defaults --query "$_flag_search"
	end
	set -a fzf_defaults --bind "$start_bind"
	
	if set -q GRASP_PAGER
		# setup as pager: display unmatched lines, match results from current position downwards
		set -a fzf_defaults --layout=reverse-list --raw --bind 'change:up+down-match,zero:down'
		# NOTE: binding "result:up+down-match" crashed for slow input
		# when used as pager, chances are we get lines formatted for full $COLUMNS as STDIN, so we adjust style to display full width - no compromise
		set -a fzf_defaults --no-scrollbar --pointer="" --marker=""
		if set -q _flag_line
			# input ('tail -n') is finite, so 'load' fires only once it's all been read - no race with 'pos()'
			set -a fzf_defaults --bind "load:pos($_flag_line)"
		end
	else
		# in stream mode, results keep flowing in, so don't bind 'result'. instead use --tac to follow the flow.
		set -a fzf_defaults --tac --no-reverse
		# swap first / last, stop tracking on first
		set -a fzf_defaults --bind 'alt-shift-up,shift-page-up,alt-page-up,g:last+track-current,alt-shift-down,shift-page-down,alt-page-down,G:first'
		# start in compact mode with visible search
		#set -a fzf_defaults --bind 'start:trigger(space)+hide-header'
		if set -q _flag_line
			# input ('tail -f') never completes, so 'load' never fires; reapply pos() on every
			# 'result' update (nothing else uses it in stream mode) until the target line has
			# streamed in, then unbind so it stops fighting with manual navigation
			set -a fzf_defaults --bind "result:transform:if [ \"\$FZF_TOTAL_COUNT\" -ge $_flag_line ]; then echo pos($_flag_line)+unbind(result); fi"
		end
	end

	set -l fzf_status
	set -l bat_filename
	set -l file_opener fishcall __sp_any2text
	# in stream mode (piped stdin), bat is skipped by default; only man output keeps highlighting
	set -l skip_bat 1

	# --cmd/--file override auto-detection; otherwise infer from the passed argument
	set -l processing_mode
	if set -q _flag_file
		if not set -q argv[1]
			__sp_error "--file: missing file argument"
			return 2
		else if not test -e $argv[1]
			__sp_error "--file: not a file: '"$argv[1]"'"
			return 2
		end
		set processing_mode file
	else if set -q _flag_cmd
		if not set -q argv[1]
			__sp_error "--cmd: missing command argument"
			return 2
		else if not type -q -- $argv[1]
			__sp_error "--cmd: not a command: '"$argv[1]"'"
			return 2
		end
		set processing_mode cmd
	else if set -q argv[1] && test -e $argv[1]
		set processing_mode file
	else if test (count $argv) -ge 1 && type -q -- $argv[1]
		set processing_mode cmd
	else if set -q argv[1]
		__sp_error "Neither command nor file: '"$argv[1]"'"
		return 2
	else if test ! -t 0
		set processing_mode stdin
	else
		echo $usage
		return 1
	end >&2

	# when multiple files were passed, recurse into a pipe
	if test $processing_mode = file && test (count $argv) -gt 1
		# options precede the file args due to --stop-nonopt, so pass those through to ppage
		set -l argv_options
		set -l cnt_flags (math (count $argv_copy) - (count $argv))
		if test $cnt_flags -gt 0
			set argv_options $argv_copy[1..$cnt_flags]
		end

		begin
			for file in $argv
				if test -e $file
					__sp_grasp_inline_header "  BEGIN FILE $file"
					set -l created (__sp_getbtime $file)
					if test -n "$created"
						set created (__sp_grasp_format_epoch $created)
					else
						set created "unknown"
					end
					__sp_grasp_inline_header "    (birth $created, modified "(__sp_grasp_format_epoch (__sp_getmtime $file))")"

					# NOTE: when calling grasp, the stream stays open (following file), so forcing ppage here
					ppage $argv_options --file $file 2>&1
					__sp_grasp_inline_header "  END FILE $file"
				else
					__sp_grasp_inline_header "  MISS FILE $file "(__spt warnsign)
				end
			end
		end | fishcall $self
		return
	end

	switch $processing_mode
	case file
		# read from file
		
		set -l cfd_type (cfd --get-type --deep $argv[1] 2>/dev/null)
		
		# read tail from file
		if set -q cfd_type[1]
			# supported archive/compression format: decompress to stdout instead of tailing raw bytes
			set cmd cfd $argv[1] -
		else if set -q GRASP_PAGER
			set cmd $file_opener $argv[1]
		else
			# in stream mode, follow the file
			set cmd tail -fn $GRASP_TAIL $argv[1]
		end
		
		# setup bat
		set skip_bat 0
		set bat_filename $argv[1]
		# strip the detected archive extension, then any rotated-log numeric suffix, for bat's syntax detection
		if set -q cfd_type[1]
			set bat_filename (string replace -r -i "\.$cfd_type\$" '' -- $bat_filename)
		end
		set bat_filename (string replace -r '\.[0-9]+$' '' -- $bat_filename)
		if test (__sp_get_filesize $argv[1]) -gt $GRASP_BAT_MAX_SIZE
			set skip_bat 1
		end
		
		__sp_grasp_set_bat_cmd
		
		if test ! -t 1
			# STDOUT is not a terminal! Someone is using us as a pipe
			if set -q bat_cmd
				$cmd | $bat_cmd
			else
				$cmd
			end
			return
		end
		
		set FZF_EDIT_COMMAND fishcall __sp_editor --line=\$FZF_POS $argv[1]
		__sp_grasp_set_fzf_default_cmd
		set grasptitle "$argv[1]"
	case cmd
		# run passed command
		set cmd $argv
		
		# export some color capability indicators for invoked commands
		if test $__cap_colors -ge 256
			set -x SYSTEMD_COLORS 256
			set -x MAN_KEEP_FORMATTING 1
			# for iostat
			set -x S_COLORS always
			# ai rumors these are for modern tools in general
			set -x FORCE_COLOR 2
			set -x CLICOLOR_FORCE 1
		end
		
		# setup bat
		set skip_bat 0
		__sp_grasp_set_bat_cmd
		
		if test ! -t 0
			# STDIN is not a terminal, it must be piped to the passed command
			# recursing here, passing original args minus cmd
			# options precede cmd due to --stop-nonopt, so we can simply count the difference
			set -l recusion_argv
			set -l cnt_flags (math (count $argv_copy) - (count $argv))
			if test $cnt_flags -gt 0
				set recusion_argv $argv_copy[1..$cnt_flags]
			end
			$cmd | grasp $recusion_argv
			return
		end
		
		if test ! -t 1
			# STDOUT is not a terminal! Someone is using us as a pipe
			if set -q bat_cmd
				$cmd | $bat_cmd
			else
				$cmd
			end
			return
		end
		
		# no FZF_EDIT_COMMAND, would be a weird workflow
		__sp_grasp_set_fzf_default_cmd
	case stdin
		# read from stdin which is not a terminal
		
		if set -q STDIN_FILENAME
			set bat_filename $STDIN_FILENAME
			set grasptitle "$STDIN_FILENAME"
			if test "$STDIN_FILENAME" = man
				set skip_bat 0
			end
		else
			set grasptitle "Viewing STDIN"
		end
		
		# setup bat
		__sp_grasp_set_bat_cmd
		
		if test ! -t 1
			# STDOUT is not a terminal,! Someone is using us as a pipe (`man sh | less` on BSD)
			if set -q bat_cmd
				$bat_cmd
			else
				cat
			end
			return
		end
	end
	
	if set -q _flag_prompt
		set grasptitle $_flag_prompt
	end
	
	# add nice title, enable reload
	set grasptitle " $grasptitle (`$self`, press h for help or q to quit) "
	
	# restrict grasptitle to 80% of terminal width
	fish_prompt_shorten_string grasptitle 80
	# TODO: this causes double-quoting?
	#set grasptitle (__sp_quote_args $grasptitle)
	
	set -l header_bg (__spt grasp_header_bg bg)
	set -l header_fg (__spt grasp_header_fg)
	set -x GRASP_HEADER_BG "$header_bg"
	set -x GRASP_HEADER_FG "$header_fg"
	set -x GRASP_HEADER_TEXT "$grasptitle"
	set -l header "$header_bg$header_fg$grasptitle"(set_color normal)
	set -a fzf_defaults \
		--input-label "Search [F1 or alt-h for help]" \
		--header $header \
		--header-border=none \
		--ghost "[fzf query, exact match, F1 or alt-h for help]" \
		--bind 'focus:transform('$callback_cmd' update_header)' \
		--bind 'result:bg-transform('$callback_cmd' memory_guard)+transform('$callback_cmd' update_header)'
	# pass options as env vars so that `reload` is simple to implement
	__sp_quote_args $fzf_defaults | read -z -x FZF_DEFAULT_OPTS
	
	if set -q FZF_DEFAULT_COMMAND
		# file mode: pass FZF_DEFAULT_COMMAND for fish to invoke (enables refresh)

		# add preprocessors to pipe
		if set -q bat_cmd
			set bat_cmd (__sp_quote_args $bat_cmd)
			set FZF_DEFAULT_COMMAND "$FZF_DEFAULT_COMMAND | $bat_cmd 2>&1"
		else if set -q _flag_line_number
			set FZF_DEFAULT_COMMAND "$FZF_DEFAULT_COMMAND | fishcall __sp_linenumbers 2>&1"
		end
		fzf
	else
		# stream mode: pass STDIN to fzf
		
		# add preprocessors to pipe
		if set -q bat_cmd
			$bat_cmd 2>&1 | fzf
		else
			if set -q _flag_line_number
				__sp_linenumbers 2>&1 | fzf
			else
				fzf
			end
		end
	end
	
	set fzf_status $status
	
	if status is-interactive && test $fzf_status -eq 50
		commandline 'cat '(string escape -- $GRASP_DUMPFILE)' '
	end
	
	return 0
end

function __sp_grasp_callback_help --no-scope-shadowing
	if set -q __sp_grasp_callback_help_loop
		return
	end
	set -x __sp_grasp_callback_help_loop 1
	echo "$usage_keybinds" | __sp_pager --prompt "Viewing `grasp` usage"
	set -e __sp_grasp_callback_help_loop
end

function __sp_grasp_callback_escape --no-scope-shadowing
	# backwards compatible wrapper 2026-09-23
	exec __sp_grasp_callback escape
end

function __sp_grasp_callback_line_jump_read --no-scope-shadowing
	# backwards compatible wrapper 2026-09-23
	exec __sp_grasp_callback line_jump_read
end

function __sp_grasp_callback_line_jump_apply --no-scope-shadowing
	# backwards compatible wrapper 2026-09-23
	exec __sp_grasp_callback line_jump_apply
end

function __sp_grasp_one_screen_lead -d \
	'Print stdin as-is if it fits within $LINES, otherwise page it'
	# specifically passing to ppage so this pager can safely be used for systemd
	# caveat: line wrap is not detected (maybe possible with `fold`, if it supports ANSI)
	
	set -l max_lines 24
	test -z "$LINES"
	or set max_lines $LINES
	set max_lines (math $max_lines - 3)
	
	set -l cnt 0
	set -l must_page 0
	while read -l chunk
		# instant output to shell. cheating with stderr as stdout seems to be buffered.
		echo "$chunk" >&2
		# secondary output to buffer
		echo "$chunk"
		set cnt (math $cnt + 1)
		if test $cnt -gt $max_lines
			set must_page 1
			break
		end
	end | read -z -l buffered
	
	if test $must_page = 1
		# more input is still pending: hand off the buffered lines plus the rest of stdin to the pager

		# move cursor up over the lines already streamed to the terminal, then erase them
		printf '\033[%dA\033[J' $cnt

		# use a temporary file to dump the head buffer to
		set -l tmp (__sp_mkuniq --xdg-runtime ppage-if-much)
		printf '%s' $buffered > "$tmp"
		# concat buffer and combine with stdin
		cat "$tmp" - | grasp $argv
		rm -f "$tmp"
	else
		return 0
	end
end

function __sp_grasp_set_bat_cmd --no-scope-shadowing
	if command -q bat && begin; test $skip_bat -eq 0; or set -q _flag_syntax; or set -q _flag_line_number; end
		set bat_cmd bat --strip-ansi=auto --color=always --wrap=never --style=plain --tabs=3
		if set -q _flag_no_syntax
			set -a bat_cmd -l txt
		else if test -n "$_flag_syntax"
			set -a bat_cmd -l $_flag_syntax
		else if test -n $bat_filename
			set -a bat_cmd --file-name=$bat_filename
		end
		if set -q _flag_line_number
			set -a bat_cmd --number
		end
	end
end

function __sp_grasp_set_fzf_default_cmd --no-scope-shadowing
	set grasptitle "Viewing output of `$cmd`"

	if test -t 0
		# only bind reload when we have no stdin piped to the command
		set -a fzf_defaults \
			--bind 'r,ctrl-r,f5:become(exec fzf)'
	end

	if set -q FZF_EDIT_COMMAND
		__sp_quote_args $FZF_EDIT_COMMAND | read -z -x FZF_EDIT_COMMAND
		set -a fzf_defaults \
			--bind 'alt-e,f4:enable-raw+execute(eval $FZF_EDIT_COMMAND)'
	end
	
	# leave cmd execution (and killing of it) to fzf
	__sp_quote_args $cmd | read -z -x FZF_DEFAULT_COMMAND
	set FZF_DEFAULT_COMMAND "$FZF_DEFAULT_COMMAND 2>&1"
end

function __sp_grasp_inline_header
	echo -n (__spt grasp_header_bg bg)(__spt grasp_header_fg)
	printf %-"$COLUMNS"s $argv[1]
	echo (set_color normal)
end

function __sp_grasp_format_epoch -a epoch -d \
	'Format an epoch timestamp as a human-readable date, portably across GNU/BSD date'
	if $__cap_date_is_gnu || $__cap_date_is_busybox
		date -d "@$epoch" +'%F %T'
	else if $__cap_date_is_bsd
		date -r "$epoch" +'%F %T'
	else
		echo "$epoch"
	end
end
