#! /bin/sh
{

# custom .tmux.conf.sh

# supported minimum tmux version: 2.8 (Debian Buster)

TMUX_CONF_SH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
TMUX_CONF_SH_ESC="$(printf '%s\n' "$TMUX_CONF_SH" | sed 's/ /\\ /g')"
TMUX_STATUS_STYLE=${TMUX_STATUS_STYLE:-bg=colour26,fg=brightwhite}
TMUX_ATTENTION_COLOR=${TMUX_ATTENTION_COLOR:-bg=colour226 fg=colour16}

# version variable
# the following sets the variable __sp_tmux_ver by running
# - a shell that tells tmux to set __sp_tmux_ver
# - to a math expansion
# - executing a nested shell that creates a formula (major * 100 + minor) from tmux -V
# result examples:
# 3.0a -> 300
# 3.5  -> 305
# 3.10 -> 310
__sp_tmux_ver=${__sp_tmux_ver:-$(( $(tmux -V | sed -e 's/[^0-9.]//g' -e 's/\./*100+/') ))}

# batching support: collect tmux commands with t(), then send them all
# together as a single tmux invocation (joined by tmux's ';' command
# separator) with t_end(), to minimize process spawns.
# args are joined with a control-char delimiter (unlikely to ever appear in
# a tmux argument) and later re-split into positional params with IFS +
# set --, so no per-argument subshell/sed/eval quoting is needed at all.
TMUX_CONF_BUFFER=
TMUX_CONF_BUFFER_FILLED=0
TMUX_CONF_BUFFER_ARGC=0
TMUX_CONF_BUFFER_D=$(printf '\1')

t() {
	# buffer limits
	# - in tmux 3.7a, a limit of 1000 args was introduced:
	#   https://github.com/tmux/tmux/blob/0e418b62d259ce8da8970f75732cc6632ee4c3a0/cmd.c#L308
	#   easy to hit. so we count the arguments and flush the buffer accordingly.
	#
	# - since 1.9 and up there is a 16KB limit on the passed argv:
	#   https://github.com/tmux/tmux/issues/254
	#   byte size accounting is quite expensive, so we skip checking this for now.
	#   with flushes for the argument count in place, we're at about 9KB per flush.
	
	TMUX_CONF_BUFFER_ARGC=$(( TMUX_CONF_BUFFER_ARGC + $# + 1 ))
	if [ $TMUX_CONF_BUFFER_ARGC -gt 990 ]; then
		# undo addition when debug output is desired
		#TMUX_CONF_BUFFER_ARGC=$(( TMUX_CONF_BUFFER_ARGC - $# - 1 ))
		t_end
		# re-apply addition
		TMUX_CONF_BUFFER_ARGC=$(( TMUX_CONF_BUFFER_ARGC + $# + 1 ))
	fi
	
	# add arg delimiter and semicolon to buffer when not empty
	if [ "$TMUX_CONF_BUFFER_FILLED" -eq 1 ]; then
		TMUX_CONF_BUFFER="$TMUX_CONF_BUFFER$TMUX_CONF_BUFFER_D;"
	fi
	# add delimited args to buffer
	for NEXT_ARG in "$@"; do
		TMUX_CONF_BUFFER="$TMUX_CONF_BUFFER$TMUX_CONF_BUFFER_D$NEXT_ARG"
	done
	
	# mark buffer as dirty
	TMUX_CONF_BUFFER_FILLED=1
}

t_end() {
	#echo "flushing:$TMUX_CONF_BUFFER_ARGC args (${#TMUX_CONF_BUFFER} bytes)"
	if [ "$TMUX_CONF_BUFFER_FILLED" -eq 1 ]; then
		__sp_tmux_old_ifs="$IFS"
		IFS="$TMUX_CONF_BUFFER_D"
		# temporarily disable pathname expansion, split the batch with set -- into $@
		set -f
		set -- $TMUX_CONF_BUFFER
		set +f
		IFS="$__sp_tmux_old_ifs"
		shift # drop the leading empty field from the batch's leading delimiter
		tmux "$@"
		
		TMUX_CONF_BUFFER=
		TMUX_CONF_BUFFER_FILLED=0
		TMUX_CONF_BUFFER_ARGC=0
	fi
}

trap "t_end" EXIT

main() {
	# c-a r: quick config reload early for failsave operation
	tmux bind r source-file ~/.tmux.conf '\;' display "Config reloaded…"

	# start windows at 1 instead of 0 (0 being far away from ctrl-a on keyboard)
	# NOTE: this must happen before set-environment
	t set -g base-index 1
	t setw -g pane-base-index 1
	
	# Status line colors
	t set -g status on
	t set -g status-style "$TMUX_STATUS_STYLE"
	t set-window-option -g window-status-current-style bg=brightwhite,fg=blue
	t set -g message-style fg=colour16,bg=colour226,bold

	# Intuitive window splitting
	t bind '|' split-window -h -c "#{pane_current_path}" # left/right, default: %
	t bind '-' split-window -v -c "#{pane_current_path}" # top/bottom, default: "

	# add current path to new windows
	t bind c new-window -c "#{pane_current_path}"

	# Large history
	t set -g history-limit 50000

	# Mouse support (tmux >= 2.1)
	t set -g mouse on

	# do pass clipboard OSC-52 codes so the client clipboard is updated
	t set -g set-clipboard on

	# Display messages longer
	t set -g display-time 4000

	# copy and paste

	# vi keys are best (most intuitive) for copy and paste
	t set -g mode-keys vi

	# enter copy mode, tmux default: [
	t bind PageUp copy-mode '\;' display-message 'Entered copy-mode, use PgUp/PgDn to scroll, press q or enter to leave'
	t bind up copy-mode '\;' display-message 'Entered copy-mode, use PgUp/PgDn to scroll, press q or enter to leave'
	t bind Escape copy-mode '\;' display-message 'Entered copy-mode, use PgUp/PgDn to scroll, press q or enter to leave'
	# add C-a v for paste (unmodified)
	t bind v paste-buffer -r

	# c-a arrows left/right: move window in (use . )
	# tmux 3.0 "corrected" behavior, else older tmux
	if [ "$__sp_tmux_ver" -ge 300 ]; then
		swap_window_new_default='-d'
	else
		swap_window_new_default=''
	fi
	t bind Left swap-window $swap_window_new_default -t -1
	t bind Right swap-window $swap_window_new_default -t +1
	
	# c-a B: toggle broadcast input to all panes ("SYNC")
	t bind B run-shell "$TMUX_CONF_SH_ESC set_broadcast '#{?pane_synchronized,off,on}'"
	
	# set very low escape time (ms)
	# feels responsive, should not cause problems in our networks
	t set -g escape-time 50

	# color support:
	# - try "screen" if "tmux" is not in infocmp
	# - add -256color if terminal supports it
	# - for certain programs, like mc, 'tmux-256color' will be replaced with 'screen-256color' by aliases
	TPUT_COLORS=$(command -v tput 2>/dev/null && tput colors || echo 8)
	if [ "$TPUT_COLORS" -lt 256 ]; then
		if infocmp tmux > /dev/null 2>&1; then
			t set -g default-terminal tmux
		else
			t set -g default-terminal screen
		fi
	else
		if infocmp tmux-256color > /dev/null 2>&1; then
			t set -g default-terminal tmux-256color
		else
			t set -g default-terminal screen-256color
		fi
	fi
	
	# automatic rename of window name to active pane title
	t set-window-option -g automatic-rename on
	t set-window-option -g automatic-rename-format '#T'

	# gnu screen compatibility
	t set -g prefix C-a           # ctrl-a command prefix: screen compat
	t set -g prefix2 C-b          # ctrl-b command prefix: tmux default
	t bind bspace previous-window # prev window, tmux default: p
	t bind space next-window      # next window, tmux default: n
	t bind C-space next-window    # catch accidential ctrl-key press
	t bind S split-window -v      # split vertical, tmux default: "
	t bind C-a last-window        # last window toggle, tmux default: l
	t bind a send-prefix          # jump to beginning of line in bash, tmux default: different prefix C-b
	t bind Q break-pane           # make split region a dedicated window, tmux default: !
	# kill current pane, tmux default: x
	t bind k confirm-before -p "Kill pane? (y/N)" kill-pane
	# tab to move to next pane, tmux default: o
	t bind tab select-pane -t:.+
	# kill all windows, screen-like + Shift-K
	t bind K confirm-before -p "Kill all windows and exit? (y/N)" kill-session
	t bind "\\" confirm-before -p "Kill all windows and exit? (y/N)" kill-session
	# show window number and name
	t bind N display-message "This is window #I (#W). C-a . changes index, C-a A changes name."
	# rename window, tmux default: ,
	# added: disable renaming to make new name permanent
	t bind A command-prompt -I "#W" "rename-window '%%'" '\;' set-window-option allow-rename off

	# Pass thru window title set by shell
	t set -g set-titles on
	t set -g set-titles-string '#T'
	
	# Allow shell to rename window
	t set -g allow-rename on
	
	# make ctrl-arrow work in mc
	# make shift-arrow work in mc
	t set-window-option -g xterm-keys on

	# make client-side scrollbuffers work
	# adding xterm*:smcup@:rmcup@,rxvt*:smcup@:rmcup@,xs:smcup@:rmcup@ to default
	t set -g terminal-overrides 'xterm*:smcup@:rmcup@,rxvt*:smcup@:rmcup@,xs:smcup@:rmcup@,*88col*:colors=88,*256col*:colors=256,xterm*:XT:Ms=\E]52;%p1%s;%p2%s\007:Cc=\E]12;%p1%s\007:Cr=\E]112\007:Cs=\E[%p1%d q:Csr=\E[2 q,screen*:XT'

	# show host, session on the left
	# the mode indicator (PRFX/COPY/SYNC/NORM) stays inline as a native tmux
	# conditional so it keeps updating instantly on every redraw; only the
	# user@host|session part is delegated to the left_status subcommand.
	# @clock_details: set to 1 to ease shortening rules
	t set -g '@host_details' 0
	t set -g status-left-length 60
	t set -g status-left "#{?#{==:#{client_key_table},prefix},#[$TMUX_ATTENTION_COLOR]PRFX ,#{?#{==:#{pane_mode},copy-mode},#[$TMUX_ATTENTION_COLOR]COPY ,#{?#{pane_synchronized},#[$TMUX_ATTENTION_COLOR]SYNC ,#[default]NORM }}}|#($TMUX_CONF_SH_ESC left_status \"#{@host_details}\" \"#{host}\" \"#{USER}\" \"#S\") "
	t set -g mode-style "$TMUX_ATTENTION_COLOR"

	# show load, status indicator, better clock on the right
	# @clock_details: set to 1 to include the year in the clock; click the right status bar corner to toggle
	# loadavg and clock are both computed by the right_status subcommand
	t set -g '@clock_details' 0
	t set -g status-right-length 60
	t set -g status-right " #($TMUX_CONF_SH_ESC right_status #{@clock_details})"

	# Refresh interval for the status, default: 15
	t set -Fg @status_interval 15
	t set -Fg status-interval "#{@status_interval}"

	# center window list
	# NOTE: absolute-centre quickly cuts away information
	t set -g status-justify centre
	
	# vibrant copy-mode colors and
	# change the cursor style in copy-mode so selected text becomes clearly visible
	if [ "$__sp_tmux_ver" -ge 303 ]; then
		t set -g copy-mode-current-match-style bg=colour13,fg=colour16
		t set -g copy-mode-match-style bg=colour226,fg=colour16
		
		# resetting to default doesn't do the right thing at least in konsole
		# therefore we define "blinking-block" as the new default
		t set -g cursor-style blinking-block
		
		# have a hook change the cursor style
		t set-hook -g pane-mode-changed 'if-shell -F "#{==:#{pane_mode},copy-mode}" "set -p cursor-style blinking-underline" "set -p cursor-style blinking-block"'
	fi
	
	# c-a 0: select window 10 if no window 0 exists
	t bind 0 run-shell "$TMUX_CONF_SH_ESC select_win_0"
	
	# prompt-scrollback with Ctrl-Up/-Dn and Alt-Up/-Dn in copy-modes, and to quick-enter copy mode
	# for older tmux versions we search for a utf8 whitespace character
	if [ "$__sp_tmux_ver" -ge 304 ]; then
		PREV_PROMPT_MACRO='send-keys -X previous-prompt'
		NEXT_PROMPT_MACRO='send-keys -X next-prompt'
	else
		PREV_PROMPT_MACRO='send-keys -X start-of-line \\; send-keys -X search-backward " " \\; send-keys -X start-of-line'
		NEXT_PROMPT_MACRO='send-keys -X end-of-line \\; send-keys -X search-forward " " \\; send-keys -X start-of-line'
	fi
	t bind -T copy-mode-vi y $PREV_PROMPT_MACRO
	t bind -T copy-mode-vi z $PREV_PROMPT_MACRO
	t bind -T copy-mode-vi x $NEXT_PROMPT_MACRO
	t bind -T copy-mode-vi M-Up $PREV_PROMPT_MACRO
	t bind -T copy-mode-vi M-Down $NEXT_PROMPT_MACRO
	t bind -T copy-mode-vi C-Up $PREV_PROMPT_MACRO
	t bind -T copy-mode-vi C-Down $NEXT_PROMPT_MACRO
	t bind -T copy-mode y $PREV_PROMPT_MACRO
	t bind -T copy-mode z $PREV_PROMPT_MACRO
	t bind -T copy-mode x $NEXT_PROMPT_MACRO
	t bind -T copy-mode M-Up $PREV_PROMPT_MACRO
	t bind -T copy-mode M-Down $NEXT_PROMPT_MACRO
	t bind -T copy-mode C-Up $PREV_PROMPT_MACRO
	t bind -T copy-mode C-Down $NEXT_PROMPT_MACRO
	t bind M-Up copy-mode \\\; $PREV_PROMPT_MACRO
	t bind M-Down copy-mode \\\; $NEXT_PROMPT_MACRO
	# NOTE: about the legacy tmux support: all attempts to search for zero-width utf8 chars ended in tmux locking up at 100% cpu.
	# so instead we use a part of the prompt we have anyways, which isn't great but not terrible either.

	# have ctrl-d, f10 and esc exit copy mode
	t bind -T copy-mode-vi C-d send-keys -X cancel
	t bind -T copy-mode C-d send-keys -X cancel
	t bind -T copy-mode-vi f10 send-keys -X cancel
	t bind -T copy-mode f10 send-keys -X cancel
	t bind -T copy-mode-vi escape send-keys -X cancel
	t bind -T copy-mode escape send-keys -X cancel

	# one-time activity monitoring
	t set -g activity-action any
	t set-hook -g alert-activity "display \"Activity detected on window #{window_index}, monitor disabled\" ; set -w monitor-activity off"
	t bind M set -w monitor-activity on '\;' display "Monitoring window for activity ONCE"
	
	# one-time silence monitoring
	t set -g silence-action any
	t set-hook -g alert-silence "display \"Silence detected on window #{window_index}, monitor disabled\" ; set -w monitor-silence 0"
	t bind _ set -w monitor-silence 30 '\;' display "Monitoring window for silence ONCE"
	
	# scroll to top / end of buffer with alt-pgup/-pgdn
	t bind M-PageUp copy-mode '\;' send-keys -X history-top
	t bind M-PageDown copy-mode '\;' send-keys -X history-bottom
	t bind -T copy-mode M-PageUp send-keys -X history-top
	t bind -T copy-mode M-PageDown send-keys -X history-bottom
	t bind -T copy-mode-vi M-PageUp send-keys -X history-top
	t bind -T copy-mode-vi M-PageDown send-keys -X history-bottom
	t bind -T copy-mode MouseDown1Pane select-pane '\;' send-keys -X clear-selection
	t bind -T copy-mode-vi MouseDown1Pane select-pane '\;' send-keys -X clear-selection
	
	# do not exit copy-mode when selecting with mouse
	# user often scrolls way up to a specific position and may want to copy multiple strings
	# without having to scroll again. also, keep the selection if possible to mark what was copied.
	if [ $__sp_tmux_ver -ge 300 ]; then
		COPY_SELECTION_NO_CLEAR="copy-selection-no-clear"
	else
		COPY_SELECTION_NO_CLEAR="copy-selection"
	fi
	
	t bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X $COPY_SELECTION_NO_CLEAR
	t bind -T copy-mode MouseDragEnd1Pane send-keys -X $COPY_SELECTION_NO_CLEAR
	t bind -T copy-mode DoubleClick1Pane select-pane \\\; send-keys -X select-word \\\; send-keys -X $COPY_SELECTION_NO_CLEAR
	t bind -T copy-mode TripleClick1Pane select-pane \\\; send-keys -X select-line \\\; send-keys -X $COPY_SELECTION_NO_CLEAR
	t bind -T copy-mode-vi DoubleClick1Pane select-pane \\\; send-keys -X select-word \\\; send-keys -X $COPY_SELECTION_NO_CLEAR
	t bind -T copy-mode-vi TripleClick1Pane select-pane \\\; send-keys -X select-line \\\; send-keys -X $COPY_SELECTION_NO_CLEAR
	t bind -T copy-mode c send-keys -X $COPY_SELECTION_NO_CLEAR\\\; display "Selection copied"
	t bind -T copy-mode-vi c send-keys -X $COPY_SELECTION_NO_CLEAR\\\; display "Selection copied"

	# various mouse events (also documented in cheat --tmux):
	# left status bar corner: left mouse down to expand ellipsis
	# left status bar corner: double-click to show session tree chooser
	# left status bar corner: prefix + wheelup/-down move status bar up / down
	# window name: double-click to create new neighbor window
	# window name: middle-click to close with confirm
	# window name: prefix + middle-click to close without confirm, stay prefixed
	# right status bar corner: hold left mouse button down for precise time
	# right status bar corner: double-click to create dool + htop windows
	# empty status bar area: double-click to create new window
	# whole status bar area: wheelup/-down on scroll through windows just like window names
	# prefix + many middle-click events keep prefix active to forgive misclicks
	if [ $__sp_tmux_ver -ge 209 ]; then
		t bind -n DoubleClick1StatusLeft if-shell -F '#{==:#{pane_mode},tree-mode}' 'send-keys Escape' 'choose-tree -Zw'
		t bind -n DoubleClick1Status select-window -t "{mouse}" '\;' new-window -a -c "#{pane_current_path}"
		t bind -n MouseDown1StatusLeft set -g '@host_details' 1 '\;' refresh-client -S
		t bind -n MouseUp1StatusLeft set -g '@host_details' 0 '\;' refresh-client -S
		t bind -n DoubleClick1StatusRight run-shell "$TMUX_CONF_SH_ESC open_monitoring_windows"
		t bind -T prefix WheelUpStatusLeft set -s status-position top '\;' set -s status-justify left
		t bind -T prefix WheelDownStatusLeft set -s status-position bottom '\;' set -sF status-justify centre
		t bind -n DoubleClick1StatusDefault new-window -c "#{pane_current_path}"
		t bind -n WheelUpStatusDefault previous-window
		t bind -n WheelDownStatusDefault next-window
		t bind -n WheelUpStatusLeft previous-window
		t bind -n WheelDownStatusLeft next-window
		t bind -n WheelUpStatusRight previous-window
		t bind -n WheelDownStatusRight next-window
		t bind -n MouseDown1StatusRight set -g '@clock_details' 1 '\;' set -Fg status-interval 1 '\;' refresh-client -S
		t bind -n MouseUp1StatusRight set -g '@clock_details' 0 '\;' set -Fg status-interval "#{@status_interval}" '\;' refresh-client -S
		t bind -n MouseDown2Status select-window -t "{mouse}" '\;' confirm-before -p "kill-window \#W? (y/n)" "kill-window"
	fi
	
	# moving this to minimum 303 as closing the last tab crashed in podman test-drive debian bullseye
	if [ $__sp_tmux_ver -ge 303 ]; then
		t bind -T prefix MouseDown2Status kill-window -t "{mouse}" '\;' switch-client -T prefix
		t bind -T prefix MouseUp2Status '\;' switch-client -T prefix
		t bind -T prefix DoubleClick2Status '\;' switch-client -T prefix
		t bind -T prefix TripleClick2Status '\;' switch-client -T prefix
		t bind -T prefix MouseDrag2Status '\;' switch-client -T prefix
		t bind -T prefix MouseDragEnd2Status '\;' switch-client -T prefix
		t bind -T prefix MouseUp2StatusDefault '\;' switch-client -T prefix
		t bind -T prefix MouseDown2StatusDefault '\;' switch-client -T prefix
		t bind -T prefix DoubleClick2StatusDefault '\;' switch-client -T prefix
		t bind -T prefix TripleClick2StatusDefault '\;' switch-client -T prefix
		t bind -T prefix MouseDrag2StatusDefault '\;' switch-client -T prefix
		t bind -T prefix MouseDragEnd2StatusDefault '\;' switch-client -T prefix
		t bind -T prefix SecondClick2Status '\;' switch-client -T prefix
		t bind -T prefix SecondClick2StatusDefault '\;' switch-client -T prefix
	fi
	
	# show cheat --tmux
	t bind f1 run-shell 'fish --interactive -c "cheat --tmux"'
	t bind h run-shell 'fish --interactive -c "cheat --tmux"'
	
	# enable focus reporting
	# restricted to higher tmux versions as mcedit failed to render when opening files in Debian Bookworm
	# (approximate, no associated bug report found in a quick search)
	if [ $__sp_tmux_ver -ge 305 ]; then
		t set -g focus-events on
	else
		t set -g focus-events off
	fi
	
	# move window to another session, create it if necessary, and switch to it
	if [ $__sp_tmux_ver -ge 303 ]; then
		t bind M-w command-prompt -p "Move window to (new) session:" \
		"set-environment TMUX_PROMPT_ANSWER \"%%%\"; set-environment -F TMUX_WINDOW_ID \"#{window_id}\"; run-shell \"$TMUX_CONF_SH_ESC move_window_to_session\"; set-environment -u TMUX_PROMPT_ANSWER; set-environment -u TMUX_WINDOW_ID" \
		;
	else
		# old tmux does not support -F
		t bind M-w command-prompt -p "Move window to (new) session:" \
		"run-shell \"$TMUX_CONF_SH_ESC move_window_to_session #{window_id} \\\"%%%\\\"\"" \
		;
	fi
	
	# move window to another session with a session picker
	t bind W display "Move window to session ..." '\;' choose-tree -ZNs "move-window -t '%1' ; switch-client -t '%1'"
	
	# restored defaults (2026-05-16)
	t bind-key -T prefix z resize-pane -Z
	t bind-key -T prefix x confirm-before -p "kill-pane #P? (y/n)" kill-pane
	# end restored defaults
	
	# set-environment seems to trigger creation of the first window
	# therefore, put this rather at the end than the start of main()
	t set-environment __sp_tmux_ver "$__sp_tmux_ver"
	
	t_end
}

tmux_show_err() {
	MSG=$(tmux "$@" 2>&1)
	[ "${MSG:-}" = "" ] || tmux display-message "$MSG"
}

nice_ellipsis() {
	__txt="$1"
	__max="$2"
	
	# if max is not specified or is <= 0, return as-is
	if [ -z "$__max" ] || [ "$__max" -le 0 ]; then
		printf '%s\n' "$__txt"
		return
	fi
	
	# get the length of the text in characters (UTF-8 aware)
	__len=$(printf '%s' "$__txt" | wc -c)
	
	# if text fits, return as-is
	if [ "$__len" -le "$__max" ]; then
		printf '%s\n' "$__txt"
		return
	fi
	
	# text is too long, truncate and add ellipsis
	# the ellipsis character … is 1 character wide, so we only need to trim one extra character
	__truncate_at=$((__max - 1))
	
	# if truncate_at is <= 0, just return the ellipsis
	if [ "$__truncate_at" -le 0 ]; then
		printf '…\n'
		return
	fi
	
	# truncate using cut (byte-based, but works for ASCII-heavy strings)
	# for proper UTF-8 handling, we use head -c to cut bytes, then rely on
	# the fact that most practical strings are ASCII-dominant
	__truncated=$(printf '%s' "$__txt" | cut -c1-"$__truncate_at")
	printf '%s…\n' "$__truncated"
}

if [ "${1:-}" = "" ]; then
	main
	exit
fi

SUBCOMMAND="$1"
shift

case "$SUBCOMMAND" in
	set_broadcast)
		t setw pane-border-format "#{pane_index} #T"
		t set-window-option synchronize-panes "$1"
		t display-message "synchronize-panes is now $1"
		if [ "$1" = "on" ]; then
			t setw pane-border-status top
			t setw pane-border-style bg=colour226,fg=colour16
			t setw pane-active-border-style bg=colour226,fg=colour16
		else
			t setw pane-border-status off
			t setw pane-border-style none
			t setw pane-active-border-style fg=colour16,fg=colour2
		fi
		
		if [ $__sp_tmux_ver -ge 305 ]; then
			t setw pane-border-style "#{?pane_synchronized,bg=colour226#,fg=colour16,none}"
			t setw pane-active-border-style "#{?pane_synchronized,bg=colour226#,fg=colour16,fg=colour2}"
		fi
		t_end
	;;
	select_win_0)
		if tmux list-windows -F '#{window_index}' | grep -q -x 0; then
			tmux select-window -t 0
		else
			tmux_show_err select-window -t 10
		fi
	;;
	open_monitoring_windows)
		if command -v dool > /dev/null; then
			if command -v fishcall > /dev/null; then
				DOOL_MACRO="fishcall ddool"
			else
				DOOL_MACRO="dool"
			fi
			if ! tmux list-windows -F '#{window_name}' | grep -qx 'ddool'; then
				t new-window -a -t '{end}' -n ddool "$DOOL_MACRO"
				t split-window "$DOOL_MACRO 60"
			fi
		fi
		if command -v htop > /dev/null; then
			HTOP_MACRO="htop"
		else
			HTOP_MACRO="top"
		fi
		if ! tmux list-windows -F '#{window_name}' | grep -qx 'htop'; then
			t new-window -a -t '{end}' -n htop "$HTOP_MACRO"
			t select-window -t "htop"
		fi
	;;
	move_window_to_session)
		TMUX_WINDOW_ID="${TMUX_WINDOW_ID:-$1}"
		TMUX_PROMPT_ANSWER="${TMUX_PROMPT_ANSWER:-$2}"
		
		if tmux has-session -t "$TMUX_PROMPT_ANSWER"; then
			t switch-client -t "$TMUX_PROMPT_ANSWER"
			t move-window -s "$TMUX_WINDOW_ID" -t "$TMUX_PROMPT_ANSWER:"
		else
			# create a new session with only a sleep command and move that to end of list
			t new-session -d -s "$TMUX_PROMPT_ANSWER" -n "" "sleep 10"
			t move-window -s "$TMUX_PROMPT_ANSWER:1" -t "$TMUX_PROMPT_ANSWER:99"
			t switch-client -t "$TMUX_PROMPT_ANSWER"
			t move-window -s "$TMUX_WINDOW_ID" -t "$TMUX_PROMPT_ANSWER:"
			# kill the placeholder
			t kill-window -t "$TMUX_PROMPT_ANSWER:99"
		fi
	;;
	left_status)
		TMUX_HOST="$2"
		TMUX_USER="$3"
		TMUX_SESSION="$4"
		if [ "$1" = "0" ]; then
			TMUX_HOST=$(nice_ellipsis "$TMUX_HOST" 20)
			TMUX_USER=$(nice_ellipsis "$TMUX_USER" 5)
			TMUX_SESSION=$(nice_ellipsis "$TMUX_SESSION" 5)
		fi
		echo " $TMUX_USER@$TMUX_HOST/$TMUX_SESSION |#[default]"
	;;
	right_status)
		LOADAVG=$( ([ -f /proc/loadavg ] && cut -d " " -f -3 /proc/loadavg) || sysctl vm.loadavg 2>/dev/null | sed "s/.*{ //;s/ }.*//" )
		if [ "${1:-0}" = "1" ]; then
			# long format
			CLOCK=$(date '+%H:%M:%S %Y-%m-%d')
		else
			# short format
			CLOCK=$(date '+%H:%M %m-%d')
			LOADAVG=$(echo "$LOADAVG" | cut -d " " -f 1)
		fi
		# #[reverse] is kept here rather than in status-right itself, since it sits
		# between the two dynamic values; tmux re-parses #() output for #[...]
		# style directives, same as other status-line generator scripts rely on.
		echo "| $LOADAVG | $CLOCK"
	;;
esac

exit
}