#! /bin/sh
# shellcheck disable=SC2329,SC1091
{

# shell-pack .tmux.conf.sh
# supported minimum tmux version: 1.9 (Debian Jessie)
# features degrade gracefully, all being enabled at 3.5

# macOS ships /bin/sh as an ancient bash 3.x; re-exec with /bin/dash if available
case "${BASH_VERSION:-}" in
	3*)
		if [ -x /bin/dash ]; then
			exec /bin/dash "$0" "$@"
		elif [ -x /bin/zsh ]; then
			# shellcheck disable=SC3038
			exec -a sh /bin/zsh "$0" "$@"
		fi
	;;
esac

# derive .tmux.conf.sh directory, real path and escaped real path
TMUX_CONF_SH_DIR="$(cd "$(dirname "$0")" && pwd)"
TMUX_CONF_SH="$TMUX_CONF_SH_DIR/$(basename "$0")"
TMUX_CONF_SH_ESC="$(printf '%s\n' "$TMUX_CONF_SH" | sed 's/ /\\ /g')"

# parse and strip a leading --reload=X argument, passed in by .tmux.conf via
# #{@is-reload}; this tells us whether this is the initial run or a
# subsequent `source-file` reload, so main() can preserve toggle state
# across reloads instead of resetting it every time.
TMUX_CONF_SH_IS_RELOAD=${TMUX_CONF_SH_IS_RELOAD:-0}

# version variable
# the following sets the variable __sp_tmux_ver by running
# - a shell that tells tmux to set __sp_tmux_ver
# - to a math expansion
# - executing a nested shell that creates a formula (major * 100 + minor) from tmux -V
# result examples: 3.0a -> 300    3.5 -> 305    3.10 -> 310
__sp_tmux_ver=${__sp_tmux_ver:-$(( $(tmux -V | sed -e 's/[^0-9.]//g' -e 's/\./*100+/') ))}

# tmux imports variables into the session
# let updated session LC_NERDLEVEL, TERM overwrite global
# very early since this influences symbols
# TODO: import larger chunks of tmux environment and options to reduce calls?
update_global_from_session() {
	VARNAME="$1"
	VAR_GLOBAL="$(tmux show-environment -g "$VARNAME" 2>/dev/null)"
	VAR_GLOBAL="${VAR_GLOBAL#*=}"
	VAR_LOCAL="$(tmux show-environment "$VARNAME" 2>/dev/null)"
	case "$VAR_LOCAL" in
		-*)
			# unset
			eval "unset $VARNAME; export $VARNAME"
			tmux set-environment -gr "$VARNAME"
		;;
		*)
			# assigned
			VAR_LOCAL="${VAR_LOCAL#*=}"
			eval "$VARNAME=\"$VAR_LOCAL\"; export $VARNAME"
			if [ "$VAR_LOCAL" != "$VAR_GLOBAL" ]; then
				tmux set-environment -g "$VARNAME" "$VAR_LOCAL"
			fi
		;;
	esac
	
}
if tmux has-session >/dev/null 2>&1; then
	update_global_from_session TERM
	update_global_from_session LC_NERDLEVEL
fi

# on initial load, TERM is empty and has to be pulled from show-env
update_env_from_global() {
	VARNAME="$1"
	VAR_GLOBAL="$(tmux show-environment -g "$VARNAME" 2>/dev/null)"
	case "$VAR_GLOBAL" in
		-*)
			# unset
			eval "unset $VARNAME; export $VARNAME"
		;;
		*)
			# assigned
			VAR_GLOBAL="${VAR_GLOBAL#*=}"
			eval "$VARNAME=\"$VAR_GLOBAL\"; export $VARNAME"
		;;
	esac
}

if [ -z "${TERM:-}" ]; then
	if [ "$__sp_tmux_ver" -ge 301 ]; then
		update_env_from_global TERM
	else
		# server startup on very old tmux unfortunately does not have true TERM in
		# set -g env. so we hardcode :-( it will be updated on client attach, though.
		TERM=screen-256color
		export TERM
	fi
fi
if [ -z "${LC_NERDLEVEL:-}" ]; then
	update_env_from_global LC_NERDLEVEL
fi

TPUT_COLORS=$([ "$TERM" != "" ] && command -v tput >/dev/null 2>&1 && tput colors 2>/dev/null || echo 8)

# placeholders which can be overridden in a local sh
custom_colors() { return; }
custom_styles() { return; }
custom_main() { return; }
custom_functions() { return; }
if [ -e "/etc/tmux.conf.local.sh" ]; then
. "/etc/tmux.conf.local.sh"
fi
if [ -e "$HOME/.config/tmux.conf.local.sh" ]; then
. "$HOME/.config/tmux.conf.local.sh"
fi

# colors
COLOR_STATUS_BG="colour26"
COLOR_STATUS_FG="colour255"
COLOR_STATUS_L_BG="colour236"
COLOR_STATUS_L_FG="colour15"
COLOR_STATUS_R_BG="colour236"
COLOR_STATUS_R_FG="colour15"
COLOR_HIGHLIGHT_BG="colour220"
COLOR_HIGHLIGHT_FG="colour16"
COLOR_HIGHLIGHT2_BG="colour13"
COLOR_HIGHLIGHT2_FG="colour16"
COLOR_MODE_PREFIX_BG="colour252"
COLOR_MODE_PREFIX_FG="colour232"
COLOR_MODE_COPY_BG="colour220"
COLOR_MODE_COPY_FG="colour16"
COLOR_MODE_SYNC_BG="colour48"
COLOR_MODE_SYNC_FG="colour16"
COLOR_PANE_BORDER_FG="colour236"
COLOR_PANE_ACTIVE_BORDER_FG="colour48"
COLOR_WIN_STATUS_CURRENT_BG="colour255"
COLOR_WIN_STATUS_CURRENT_FG="black"

if [ "$TPUT_COLORS" -lt 256 ]; then
	# some colors don't automap well to 8-color terminal
	COLOR_HIGHLIGHT_BG="colour3"
	COLOR_HIGHLIGHT_FG="colour8"
	COLOR_MODE_COPY_BG="colour3"
	COLOR_MODE_COPY_FG="colour8"
fi
# apply custom overrides
custom_colors

# styles and symbols
STYLE_STATUS_L="bg=$COLOR_STATUS_L_BG fg=$COLOR_STATUS_L_FG"
STYLE_STATUS_R="bg=$COLOR_STATUS_R_BG fg=$COLOR_STATUS_R_FG"
STYLE_HIGHLIGHT="bg=$COLOR_HIGHLIGHT_BG fg=$COLOR_HIGHLIGHT_FG"
if [ "${LC_NERDLEVEL:-0}" -gt 2 ]; then
	S_STATUS_L_END=" #[fg=$COLOR_STATUS_BG]"
	S_STATUS_R_BEGIN="#[fg=$COLOR_STATUS_BG bg=$COLOR_STATUS_R_BG]#[$STYLE_STATUS_R] "
	S_STATUS_DIV_L="  "
	S_STATUS_DIV_R="  "
	S_COLLAPSED_L=" 🠴"
	S_COLLAPSED_R="🠶 "
	S_MESSAGE_BEGIN=" 󰗖 "
	S_MESSAGE_END=" 󰗖 "
else
	S_STATUS_L_END=" "
	S_STATUS_R_BEGIN=" "
	S_STATUS_DIV_L=" · "
	S_STATUS_DIV_R=" · "
	S_COLLAPSED_L=" <<"
	S_COLLAPSED_R=">> "
	S_MESSAGE_BEGIN=" ! "
	S_MESSAGE_END=" ! "
fi
D_STATUS_INTERVAL=15
style_msg() {
	MSG="$S_MESSAGE_BEGIN$1"
	if [ "$__sp_tmux_ver" -ge 307 ]; then
		MSG="#[align=centre]$MSG$S_MESSAGE_END"
	fi
}
# apply custom overrides
custom_styles

# batching support: collect tmux commands with 't', then send them all
# together as a single tmux invocation (joined by tmux's ';' command
# separator) with 't_flush', to minimize process spawns. 't_flush' is called
# automatically on exit.
# args are joined with a control-char delimiter TMUX_CONF_BUFFER_D (unlikely
# to ever appear in a tmux argument) and later re-split into positional params
# with IFS + set --, so no per-argument subshell/sed/eval quoting is needed at all.
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
	if [ $TMUX_CONF_BUFFER_ARGC -gt $TMUX_CONF_BUFFER_THRESHOLD ]; then
		# undo addition when debug output is desired
		#TMUX_CONF_BUFFER_ARGC=$(( TMUX_CONF_BUFFER_ARGC - $# - 1 ))
		t_flush
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

t_flush() {
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
		tmux "$@" >/dev/null # mute stdout for tmux 1.9
		
		TMUX_CONF_BUFFER=
		TMUX_CONF_BUFFER_FILLED=0
		TMUX_CONF_BUFFER_ARGC=0
	fi
}

# initialize empty buffer
TMUX_CONF_BUFFER=
TMUX_CONF_BUFFER_FILLED=0
TMUX_CONF_BUFFER_ARGC=0
TMUX_CONF_BUFFER_D=$(printf '\1')
TMUX_CONF_BUFFER_THRESHOLD=990


TMUX_FAILSAFE_DEBUG=${TMUX_FAILSAFE_DEBUG:-0}
TMUX_FAILSAFE=${TMUX_FAILSAFE:-$TMUX_FAILSAFE_DEBUG}
# manually set TMUX_CONF_SH_ECHO=1 to echo every tmux invocation to stderr
TMUX_CONF_SH_ECHO=${TMUX_CONF_SH_ECHO:-0}

if [ "$TMUX_CONF_SH_ECHO" = "1" ]; then
	TMUX_CONF_BUFFER_THRESHOLD=0
	tmux() {
		case "$1" in
			# don't echo retrieval functions
			show*|display*)
				command tmux "$@"
			;;
			*)
				# printf %q is bash-only, so quote each arg manually for dash/posix sh;
				# only quote args that actually need it, to keep output readable
				__echo_out=
				for __echo_arg in "$@"; do
					case "$__echo_arg" in
						'\;')
							# special case: "\;" is output as literal \;
							__echo_out="$__echo_out$__echo_arg "
						;;
						*[!A-Za-z0-9,._+:/@%-]*)
							__echo_out="$__echo_out\"$(printf '%s' "$__echo_arg" | sed 's/[\\\\"$`]/\\\\&/g')\" "
						;;
						*)
							__echo_out="$__echo_out$__echo_arg "
						;;
					esac
				done
				echo "$__echo_out" >&2
			;;
		esac
	}
fi

# in failsafe mode, tmux commands are passed as-is without buffering
if [ "$TMUX_FAILSAFE" = "1" ]; then
	# manually set TMUX_FAILSAFE_DEBUG=1 to get an adhoc error log
	if [ "$TMUX_FAILSAFE_DEBUG" = "1" ]; then
		if [ "$#" -gt 0 ]; then
			ERRLOG="/tmp/tmux-subcommand-$1-errors.last"
		else
			ERRLOG="/tmp/tmux-errors.last"
		fi
		
		echo "tmux.conf.sh error output" > "$ERRLOG"
		t() {
			tmux "$@" >> "$ERRLOG" 2>&1
			return 0
		}
	else
		t() {
			tmux "$@" > /dev/null 2>&1
			return 0
		}
	fi
fi


# flush remaining buffer on exit
trap "t_flush" EXIT

main() {
	# c-a r: quick config reload
	style_msg "Config reloaded…"
	t bind r source-file ~/.tmux.conf '\;' display "$MSG"
	
	# Status line colors
	t set -g status-style "bg=$COLOR_STATUS_BG,fg=$COLOR_STATUS_FG"
	t set -g mode-style "$STYLE_HIGHLIGHT"
	t set -g window-status-current-style "bg=$COLOR_WIN_STATUS_CURRENT_BG,fg=$COLOR_WIN_STATUS_CURRENT_FG"
	t set -g message-style fg=$COLOR_HIGHLIGHT_FG,bg=$COLOR_HIGHLIGHT_BG
	#if [ "$TPUT_COLORS" -ge 256 ]; then
	#	t set -ag message-style bold
	#fi
	if [ "$__sp_tmux_ver" -ge 307 ]; then
		if [ "$TMUX_CONF_SH_IS_RELOAD" != "1" ]; then
			t set -ag message-style fill=$COLOR_HIGHLIGHT_BG
			#t set -ag message-style align=centre
			#t set -ag message-command-style align=left
		fi
		# NOTE: message-format looks promising, but unfortunately we cannot format
		# input prompts (e.g. prefix+:) different than "display msg" (#{command_prompt} is no help)
		# look out for v3.8 where prompt_input may be merged.
		#t set -g message-format '…'
	fi
	

	# set-environment seems to trigger creation of the first window
	# therefore, put this rather at the end than the start of main()
	t set-environment __sp_tmux_ver "$__sp_tmux_ver"
	
	# make ctrl-arrow work in mc
	# make shift-arrow work in mc
	if [ "$__sp_tmux_ver" -lt 204 ]; then
		t set -w -g xterm-keys on
	fi
	
	# color support:
	# - try "screen" if "tmux" is not in infocmp
	# - add -256color if terminal supports it
	# - for certain programs, like mc, 'tmux-256color' will be replaced with 'screen-256color' by aliases
	if [ "$TPUT_COLORS" -lt 256 ]; then
		if infocmp tmux > /dev/null 2>&1; then
			TMUX_TERMINAL=tmux
		else
			TMUX_TERMINAL=screen
		fi
	else
		if infocmp tmux-256color > /dev/null 2>&1; then
			TMUX_TERMINAL=tmux-256color
		else
			TMUX_TERMINAL=screen-256color
		fi
	fi
	
	t set -g default-terminal $TMUX_TERMINAL
	# set a user copy of this variable because it can't be read in tmux <= debian buster
	t set -g @copy-default-terminal $TMUX_TERMINAL
	
	if [ "$TMUX_CONF_SH_IS_RELOAD" != "1" ]; then
		# not a reload - initial server setup
		t set -ag update-environment " LC_NERDLEVEL"
		t set -ag update-environment " TERM"
		if [ "$TMUX_CONF_SH_ECHO" = "1" ]; then
			main_phase2
		else
			# to speed up the initial load, move into run-shell -b
			t run-shell -b "\
				[ \"\$($TMUX_CONF_SH_ESC main_phase2 2>&1 )\" = '' ] \
				|| TMUX_FAILSAFE=1 $TMUX_CONF_SH_ESC main_phase2 \
			"
		fi
	else
		main_phase2
	fi
	return 0
}

# the second part of the main config is loaded in background
main_phase2() {
	if [ "$TMUX_FAILSAFE" = "1" ]; then
		if [ "$TMUX_FAILSAFE_DEBUG" = "1" ]; then
			style_msg "TMUX_FAILSAFE_DEBUG=1, logging to $ERRLOG"
			tmux display "$MSG"
		else
			style_msg "Warning: Config errors in $TMUX_CONF_SH"
			tmux display "$MSG"
		fi
	fi
	
	# also reload on attach
	if [ "$__sp_tmux_ver" -ge 202 ]; then
		t set-hook client-attached "run-shell \"$TMUX_CONF_SH_ESC client_attached\""
	fi
	

	if [ "$__sp_tmux_ver" -ge 201 ]; then
		# Mouse support (tmux >= 2.1)
		t set -g mouse on
	fi


	# enter copy mode, tmux default: [
	style_msg 'Entered copy-mode, use PgUp/PgDn to scroll, press q or enter to leave'
	t bind PageUp copy-mode '\;' display-message "$MSG"
	t bind up copy-mode '\;' display-message "$MSG"
	t bind Escape copy-mode '\;' display-message "$MSG"

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
	if [ "$__sp_tmux_ver" -ge 203 ]; then
		t bind B run-shell "$TMUX_CONF_SH_ESC toggle_broadcast '#{pane_synchronized}'"
	else
		t bind B run-shell "$TMUX_CONF_SH_ESC toggle_broadcast"
	fi
	
	# show window number and name
	style_msg "This is window #I (#W). C-a . changes index, C-a A changes name."
	t bind N display-message "$MSG"

	# derive socket name from $TMUX (format: "socket_path,pid,session_id"),
	# e.g. "/tmp/tmux-1000/pb,730888,1" -> "pb"
	socket_name=$(basename "$(echo "$TMUX" | cut -d, -f1)")
	t set -g '@socket_name' "$socket_name"

	# when the last shell of a session exits, tmux destroys that session; a
	# client attached to it would then normally be detached (detach-on-destroy
	# default: on). for any socket other than "default", switch to another
	# session on the same socket instead of disconnecting the client, if one
	# exists (detach-on-destroy off falls back to detaching automatically
	# when no other session is left).
	if [ "$socket_name" != "default" ]; then
		t set -g detach-on-destroy off
	else
		t set -g detach-on-destroy on
	fi

	# show host, session on the left
	# the mode indicator (PRFX/COPY/SYNC/NORM) stays inline as a native tmux
	# conditional so it keeps updating instantly on every redraw; only the
	# user@host|session part is delegated to the left_status subcommand.
	if [ "$__sp_tmux_ver" -ge 203 ]; then
		t set -g status-left "#(\
			$TMUX_CONF_SH_ESC left_status \
			'#{@host_details}' '#{host}' '#{USER}' '#S' '#{window_width}' \
			'#{@socket_name}' '#{client_key_table}' '#{scroll_position}' \
			'#{pane_synchronized}' '#{client_flags}' '#{client_termfeatures}'\
		)"
	else
		t set -g status-left "#($TMUX_CONF_SH_ESC left_status)"
	fi
	# show load, status indicator, better clock on the right
	# loadavg and clock are both computed by the right_status subcommand
	if [ "$__sp_tmux_ver" -ge 203 ]; then
		t set -g status-right "#(\
			$TMUX_CONF_SH_ESC right_status \
			'#{@clock_details}' '#{window_width}' '#{client_flags}' \
			'#{client_termfeatures}' \
		)"
	else
		t set -g status-right "#($TMUX_CONF_SH_ESC right_status)"
	fi
	# only initialize these on the first run, not on a `source-file` reload,
	# so toggle state set via toggle_host_details/toggle_clock_details survives
	if [ "$TMUX_CONF_SH_IS_RELOAD" != "1" ]; then
		t set -g '@host_details' 0
		t set -g '@clock_details' 0
		t set -g status-interval "$D_STATUS_INTERVAL"

		# center window list
		# NOTE: absolute-centre quickly cuts away information
		t set -g status-justify centre
	fi
	
	# vibrant copy-mode colors and
	if [ "$__sp_tmux_ver" -ge 303 ]; then
		t set -g copy-mode-current-match-style bg=$COLOR_HIGHLIGHT2_BG,fg=$COLOR_HIGHLIGHT2_FG
		t set -g copy-mode-match-style bg=$COLOR_HIGHLIGHT_BG,fg=$COLOR_HIGHLIGHT_FG
		
		# change the cursor style in copy-mode so selected text becomes clearly visible
		# NOTE: this is only necessary for copy-mode-vi, so it is commented out for now
		
		# resetting to default doesn't do the right thing at least in konsole
		# therefore we define "blinking-block" as the new default
		#t set -g cursor-style blinking-block
		
		# have a hook change the cursor style
		#t set-hook -g pane-mode-changed 'if-shell -F "#{==:#{pane_mode},copy-mode}" "set -p cursor-style blinking-underline" "set -p cursor-style blinking-block"'
	fi
	
	# c-a 0: select window 10 if no window 0 exists
	t bind 0 run-shell "$TMUX_CONF_SH_ESC select_win_0"
	
	# shellcheck disable=SC2086
	if [ "$__sp_tmux_ver" -ge 204 ]; then
		# prompt-scrollback with Ctrl-Up/-Dn and Alt-Up/-Dn in copy-modes, and to quick-enter copy mode
		# for older tmux versions we search for a utf8 whitespace character
		if [ "$__sp_tmux_ver" -ge 304 ]; then
			PREV_PROMPT_MACRO='send-keys -X previous-prompt'
			NEXT_PROMPT_MACRO='send-keys -X next-prompt'
		else
			PREV_PROMPT_MACRO="send-keys -X start-of-line \\; send-keys -X search-backward   \; send-keys -X start-of-line"
			NEXT_PROMPT_MACRO="send-keys -X end-of-line \\; send-keys -X search-forward   \; send-keys -X start-of-line"
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
		t bind M-Up copy-mode '\;' $PREV_PROMPT_MACRO
		t bind M-Down copy-mode '\;' $NEXT_PROMPT_MACRO
		# NOTE: about the legacy tmux support: all attempts to search for zero-width utf8 chars ended in tmux locking up at 100% cpu.
		# so instead we use a part of the prompt we have anyways, which isn't great but not terrible either.
		
		# copying over some vital, mostly conflict-free vi key bindings over to emacs mode
		t bind -T copy-mode Enter send-keys -X copy-selection-and-cancel
		t bind -T copy-mode Space send-keys -X begin-selection
		t bind -T copy-mode / command-prompt -p "search down" "send -X search-forward \"%%%\""
		t bind -T copy-mode g send-keys -X history-top
		t bind -T copy-mode G send-keys -X history-bottom
		t bind -T copy-mode M-l command-prompt -p "goto line" "send -X goto-line \"%%%\""
		t bind -T copy-mode '?' command-prompt -p "search up" "send -X search-backward \"%%%\""
		t bind -T copy-mode v send-keys -X rectangle-toggle
		t bind -T copy-mode h send-keys -X cursor-left
		t bind -T copy-mode j send-keys -X cursor-down
		t bind -T copy-mode k send-keys -X cursor-up
		t bind -T copy-mode l send-keys -X cursor-right
		
		# rectangle-toggle on r
		t bind -T copy-mode r send-keys -X rectangle-toggle
		t bind -T copy-mode-vi r send-keys -X rectangle-toggle
		
		# have ctrl-d, f10 and esc exit copy mode
		t bind -T copy-mode-vi C-d send-keys -X cancel
		t bind -T copy-mode C-d send-keys -X cancel
		t bind -T copy-mode-vi f10 send-keys -X cancel
		t bind -T copy-mode f10 send-keys -X cancel
		t bind -T copy-mode-vi escape send-keys -X cancel
		t bind -T copy-mode escape send-keys -X cancel
		
		# scroll to top / end of buffer with alt-pgup/-pgdn
		t bind M-PageUp copy-mode '\;' send-keys -X history-top
		t bind M-PageDown copy-mode '\;' send-keys -X history-bottom
		t bind -T copy-mode M-PageUp send-keys -X history-top
		t bind -T copy-mode M-PageDown send-keys -X history-bottom
		t bind -T copy-mode-vi M-PageUp send-keys -X history-top
		t bind -T copy-mode-vi M-PageDown send-keys -X history-bottom
		
		# clear selection when mouse clicks
		t bind -T copy-mode MouseDown1Pane select-pane '\;' send-keys -X clear-selection
		t bind -T copy-mode-vi MouseDown1Pane select-pane '\;' send-keys -X clear-selection
		# clear selection with shift-C
		t bind -T copy-mode C send-keys -X clear-selection
		t bind -T copy-mode-vi C send-keys -X clear-selection
		
		# do not exit copy-mode when selecting with mouse
		# user often scrolls way up to a specific position and may want to copy multiple strings
		# without having to scroll again. also, keep the selection if possible to mark what was copied.
		if [ "$__sp_tmux_ver" -ge 300 ]; then
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
		style_msg "Selection copied"
		t bind -T copy-mode c send-keys -X $COPY_SELECTION_NO_CLEAR\\\; display "$MSG"
		t bind -T copy-mode-vi c send-keys -X $COPY_SELECTION_NO_CLEAR\\\; display "$MSG"
		
		if [ "$__sp_tmux_ver" -ge 208 ]; then
			# one-time activity monitoring
			t set -g activity-action any
			style_msg "Activity detected on window #{window_index}, monitor disabled"
			t set-hook -g alert-activity "display \"$MSG\" ; set -w monitor-activity off"
			style_msg "Monitoring window for activity ONCE"
			t bind M set -w monitor-activity on '\;' display "$MSG"
			
			# one-time silence monitoring
			t set -g silence-action any
			style_msg "Silence detected on window #{window_index}, monitor disabled"
			t set-hook -g alert-silence "display \"$MSG\" ; set -w monitor-silence 0"
			style_msg "Monitoring window for silence ONCE"
			t bind _ set -w monitor-silence 30 '\;' display "$MSG"
		fi
	else
		# copying over some vital, mostly conflict-free vi key bindings over to emacs mode
		t bind -t emacs-copy Enter copy-selection
		t bind -t emacs-copy Space begin-selection
		t bind -t emacs-copy / search-forward
		t bind -t emacs-copy g history-top
		t bind -t emacs-copy G history-bottom
		t bind -t emacs-copy M-l goto-line
		t bind -t emacs-copy '?' search-backward
		t bind -t emacs-copy v rectangle-toggle
		t bind -t emacs-copy h cursor-left
		t bind -t emacs-copy j cursor-down
		t bind -t emacs-copy k cursor-up
		t bind -t emacs-copy l cursor-right
		
		# rectangle-toggle on r
		t bind -t emacs-copy r rectangle-toggle
		t bind -t vi-copy r rectangle-toggle
		
		# have ctrl-d, f10 and esc exit copy mode
		t bind -t vi-copy C-d cancel
		t bind -t vi-copy f10 cancel
		t bind -t vi-copy escape cancel
		t bind -t emacs-copy C-d cancel
		t bind -t emacs-copy f10 cancel
		t bind -t emacs-copy escape cancel
		
		# scroll to top / end of buffer with alt-pgup/-pgdn
		t bind M-PageUp copy-mode
		t bind M-PageDown copy-mode
		t bind -t emacs-copy M-PageUp history-top
		t bind -t emacs-copy M-PageDown history-bottom
		t bind -t vi-copy M-PageUp history-top
		t bind -t vi-copy M-PageDown history-bottom
		
		# clear selection when mouse clicks
		# clear selection with shift-C
		# clear-selection N/A
		
	fi

	# various mouse events (also documented in cheat --tmux):
	# left status bar corner: click toggles expansion
	# left status bar corner: alt-click to show session tree chooser
	# left status bar corner: prefix + wheelup/-down move status bar up / down
	# window name: double-click to rename
	# window name: alt-double-click to create new neighbor window
	# window name: middle-click to close with confirm
	# window name: prefix + middle-click to close without confirm, stay prefixed
	# right status bar corner: click toggles expansion
	# right status bar corner: alt-click to create dool + htop windows
	# empty status bar area: double-click to create new window
	# whole status bar area: wheelup/-down on scroll through windows just like window names
	# prefix + many middle-click events keep prefix active to forgive misclicks
	if [ "$__sp_tmux_ver" -ge 209 ]; then
		t bind -n M-MouseUp1StatusLeft if-shell -F '#{==:#{pane_mode},tree-mode}' 'send-keys Escape' 'choose-tree -Zw'
		t bind -n M-DoubleClick1Status select-window -t "{mouse}" '\;' new-window -a -c "#{pane_current_path}"
		t bind -n DoubleClick1Status select-window -t "{mouse}" '\;' command-prompt -I "#W" "rename-window '%%'; set -qw allow-rename off"
		t unbind -n MouseDown1StatusLeft
		t bind -n MouseUp1StatusLeft run-shell "$TMUX_CONF_SH_ESC toggle_host_details \"#{@host_details}\""
		t bind -n M-MouseUp1StatusRight run-shell "$TMUX_CONF_SH_ESC open_monitoring_windows"
		t bind -T prefix WheelUpStatusLeft set -g status-position top '\;' set -g status-justify left
		t bind -T prefix WheelDownStatusLeft set -g status-position bottom '\;' set -g status-justify centre
		t bind -n DoubleClick1StatusDefault new-window -c "#{pane_current_path}"
		t bind -n WheelUpStatusDefault previous-window
		t bind -n WheelDownStatusDefault next-window
		t bind -n WheelUpStatusLeft previous-window
		t bind -n WheelDownStatusLeft next-window
		t bind -n WheelUpStatusRight previous-window
		t bind -n WheelDownStatusRight next-window
		t unbind -n MouseDown1StatusRight
		t bind -n MouseUp1StatusRight run-shell "$TMUX_CONF_SH_ESC toggle_clock_details \"#{@clock_details}\""
		t bind -n MouseDown2Status select-window -t "{mouse}" '\;' confirm-before -p "kill-window #W? (y/n)" "kill-window"
	fi
	# moving this to minimum 303 as closing the last tab crashed in podman test-drive debian bullseye
	if [ "$__sp_tmux_ver" -ge 303 ]; then
		t bind -T prefix MouseDown2Status kill-window -t "{mouse}" '\;' switch-client -T prefix
	fi
	
	# binds for toggling status modes w/o mouse
	if [ "$__sp_tmux_ver" -ge 203 ]; then
		t bind M-l run-shell "$TMUX_CONF_SH_ESC toggle_host_details \"#{@host_details}\""
		t bind M-r run-shell "$TMUX_CONF_SH_ESC toggle_clock_details \"#{@clock_details}\""
	else
		t bind M-l run-shell "$TMUX_CONF_SH_ESC toggle_host_details"
		t bind M-r run-shell "$TMUX_CONF_SH_ESC toggle_clock_details"
	fi
	# quick "zen mode"
	t bind M-z run-shell "$TMUX_CONF_SH_ESC toggle_zen_mode"
	
	# enable focus reporting
	# restricted to higher tmux versions as mcedit failed to render when opening files in Debian Bookworm
	# (approximate, no associated bug report found in a quick search)
	if [ "$__sp_tmux_ver" -ge 305 ]; then
		t set -g focus-events on
	else
		t set -g focus-events off
	fi
	
	move_cmd="run-shell \"$TMUX_CONF_SH_ESC move_window_to_session '#{window_id}' '%%'\""
	# move window to another session, create it if necessary, and switch to it
	t bind M-w command-prompt -p "Move window to (new) session:" "$move_cmd"
	# move window to another session with a session choose-tree picker
	if [ "$__sp_tmux_ver" -ge 208 ]; then
		tree_opts="-ZNs"
	elif [ "$__sp_tmux_ver" -ge 206 ]; then
		# NOTE: in 2.6 the format of %% changes to include window: 'dst' becomes '=dst:' or '=dst:1.' or '=dst:1.%1'
		tree_opts="-Ns"
	else
		tree_opts="-s -b"
	fi
	style_msg "Move window to session ..."
	# shellcheck disable=SC2086
	t bind W display "$MSG" '\;' choose-tree $tree_opts "$move_cmd"
	
	if [ "$__sp_tmux_ver" -lt 206 ]; then
		# change window chooser bind to also show sessions on older tmux
		t bind w choose-tree -u
	fi
	
	
	
	t set -g -w pane-border-style fg=$COLOR_PANE_BORDER_FG
	t set -g -w pane-active-border-style fg=$COLOR_PANE_ACTIVE_BORDER_FG
	
	custom_main
	
	# set at end so failsafe mode repeats everything
	t set -g '@is-reload' 1
	
	#t display "debug main_background loaded"
	return 0
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

# when no verb is passed, call main and we're done
if [ "${1:-}" = "" ]; then
	main
	exit
fi

legacy_force_status_update() {
	# extra flushes and refreshes to work around bugs in old tmux, e.g. 2.8
	if [ "$__sp_tmux_ver" -lt 301 ]; then
		t_flush
		# older tmux need a bit of extra tickeling to reliably update the status
		tmux set -qg @left_status "$(tmux show -gqv @left_status)"
		tmux set -qg @right_status "$(tmux show -gqv @right_status)"
		tmux refresh-client -S
		if [ "$__sp_tmux_ver" -lt 203 ]; then
			# yeah, twice for v2.2
			tmux set -qg @left_status "$(tmux show -gqv @left_status)"
			tmux set -qg @right_status "$(tmux show -gqv @right_status)"
			tmux refresh-client -S
		fi
	fi
}

toggle_broadcast() {
	if [ "${1:-}" = "" ]; then
		SYNC="$(tmux display -p "#{pane_synchronized}")"
	else
		SYNC="$1"
	fi
	if [ "$SYNC" = "0" ]; then
		SYNC="on"
	else
		SYNC="off"
	fi
	[ "$__sp_tmux_ver" -lt 203 ] || t set -w pane-border-format "#{pane_index} #T"
	t set -w synchronize-panes "$SYNC"
	style_msg "Synchronize-panes is now $SYNC"
	t display-message "$MSG"
	if [ "$SYNC" = "on" ]; then
		[ "$__sp_tmux_ver" -lt 203 ] || t set -w pane-border-status top
		t set -w pane-border-style "bg=$COLOR_MODE_SYNC_BG,fg=$COLOR_MODE_SYNC_FG"
		t set -w pane-active-border-style "bg=$COLOR_MODE_SYNC_BG,fg=$COLOR_MODE_SYNC_FG"
	else
		[ "$__sp_tmux_ver" -lt 203 ] || t set -w pane-border-status off
		t set -w pane-border-style "fg=$COLOR_PANE_BORDER_FG"
		t set -w pane-active-border-style "fg=$COLOR_PANE_ACTIVE_BORDER_FG"
	fi
	
	if [ "$__sp_tmux_ver" -ge 305 ]; then
		t set -w pane-border-style "#{?pane_synchronized,bg=$COLOR_MODE_SYNC_BG#,fg=$COLOR_MODE_SYNC_FG,fg=$COLOR_PANE_BORDER_FG}"
		t set -w pane-active-border-style "#{?pane_synchronized,bg=$COLOR_MODE_SYNC_BG#,fg=$COLOR_MODE_SYNC_FG,fg=$COLOR_PANE_ACTIVE_BORDER_FG}"
	fi
	t refresh-client -S
}

select_win_0() {
	if tmux list-windows -F '#{window_index}' | grep -q -x 0; then
		tmux select-window -t 0
	else
		tmux_show_err select-window -t 10
	fi
}

open_monitoring_windows() {
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
}

move_window_to_session() {
	TMUX_WINDOW_ID="$1"
	TMUX_PROMPT_ANSWER="$2"
	
	# remove leading "=" and suffix ":" from TMUX_PROMPT_ANSWER to normalize tmux versions >= 2.6
	# when selecting from choose-tree
	TMUX_PROMPT_ANSWER="${TMUX_PROMPT_ANSWER#=}"
	TMUX_PROMPT_ANSWER="${TMUX_PROMPT_ANSWER%%:*}"
	#tmux display "moving $TMUX_WINDOW_ID to $TMUX_PROMPT_ANSWER"
	
	if tmux has-session -t "=$TMUX_PROMPT_ANSWER"; then
		t move-window -s "$TMUX_WINDOW_ID" -t "=$TMUX_PROMPT_ANSWER:"
		t switch-client -t "=$TMUX_PROMPT_ANSWER"
	else
		# create a new session with only a sleep command and move that to end of list
		t new-session -d -s "$TMUX_PROMPT_ANSWER" -n "" "sleep 10"
		t move-window -s "$TMUX_PROMPT_ANSWER:1" -t "=$TMUX_PROMPT_ANSWER:99"
		t move-window -s "$TMUX_WINDOW_ID" -t "=$TMUX_PROMPT_ANSWER:"
		t switch-client -t "=$TMUX_PROMPT_ANSWER"
		# kill the placeholder
		t kill-window -t "=$TMUX_PROMPT_ANSWER:99"
	fi
	legacy_force_status_update
}

left_status() {
	# cut hostname at first dot
	if [ "${1:-}" = "" ]; then
		STYLE="$(tmux show -gqv @host_details)"
		TMUX_HOST=$(tmux display -p '#{host}')
		TMUX_HOST="${TMUX_HOST%%.*}"
		TMUX_USER="${USER:-$(id -un)}"
		TMUX_SESSION="$(tmux display -p '#S')"
		COLUMNS="$(tmux display -p '#{window_width}')"
		TMUX_SOCKET_NAME="$(tmux show -gqv @socket_name)"
		CLIENT_KEY_TABLE="$(tmux display -p '#{client_key_table}')"
		SCROLL_POSITION="$(tmux display -p '#{scroll_position}')"
		PANE_SYNC="$(tmux display -p '#{pane_synchronized}')"
		CLIENT_FLAGS="$(tmux display -p '#{client_flags}')"
		CLIENT_FEATURES="$(tmux display -p '#{client_termfeatures}')"
	else
		STYLE="$1"
		TMUX_HOST="${2%%.*}"
		TMUX_USER="$3"
		TMUX_SESSION="$4"
		COLUMNS="$5"
		TMUX_SOCKET_NAME="$6"
		CLIENT_KEY_TABLE="$7"
		SCROLL_POSITION="$8"
		PANE_SYNC="$9"
		CLIENT_FLAGS="${10}"
		CLIENT_FEATURES="${11}"
	fi
	if [ "$STYLE" = "0" ] && [ "$TMUX_USER" = "root" ] && [ "$COLUMNS" -lt 120 ]; then
		TMUX_USER="√"
	fi
	# always have the mode indicator color
	if [ "$CLIENT_KEY_TABLE" = "prefix" ]; then
		MODE_STYLE="#[bg=$COLOR_MODE_PREFIX_BG fg=$COLOR_MODE_PREFIX_FG]"
		MODE_WORD="PRFX"
	elif [ "$SCROLL_POSITION" != "" ]; then
		MODE_STYLE="#[bg=$COLOR_MODE_COPY_BG fg=$COLOR_MODE_COPY_FG]"
		MODE_WORD="COPY"
	elif [ "$PANE_SYNC" = "1" ]; then
		MODE_STYLE="#[bg=$COLOR_MODE_SYNC_BG fg=$COLOR_MODE_SYNC_FG]"
		MODE_WORD="SYNC"
	else
		MODE_STYLE="#[$STYLE_STATUS_L]"
		MODE_WORD="NORM"
	fi
	
	# start with colors
	LEFT_STATUS="$MODE_STYLE"
	
	# collapsed style
	if [ "$STYLE" = "2" ]; then
		LEFT_STATUS="$LEFT_STATUS$S_COLLAPSED_L$S_STATUS_L_END"
		echo "$LEFT_STATUS"
		return
	else
		if [ "$TMUX_SESSION" = "$TMUX_SOCKET_NAME" ]; then
			DISPLAY_SESSION="$TMUX_SESSION"
		else
			DISPLAY_SESSION="$TMUX_SOCKET_NAME.$TMUX_SESSION"
		fi
		# apply ellipsis
		if [ "$STYLE" = "0" ]; then
			if [ "$COLUMNS" -ge 120 ]; then
				TMUX_HOST=$(nice_ellipsis "$TMUX_HOST" 20)
			elif [ "$COLUMNS" -ge 60 ]; then
				TMUX_HOST=$(nice_ellipsis "$TMUX_HOST" 15)
			else
				TMUX_HOST=$(nice_ellipsis "$TMUX_HOST" 3)
			fi
			if [ "$COLUMNS" -ge 180 ]; then
				TMUX_USER=$(nice_ellipsis "$TMUX_USER" 20)
				DISPLAY_SESSION=$(nice_ellipsis "$DISPLAY_SESSION" 30)
			elif [ "$COLUMNS" -ge 132 ]; then
				TMUX_USER=$(nice_ellipsis "$TMUX_USER" 10)
				DISPLAY_SESSION=$(nice_ellipsis "$DISPLAY_SESSION" 15)
			elif [ "$COLUMNS" -ge 60 ]; then
				TMUX_USER=$(nice_ellipsis "$TMUX_USER" 5)
				DISPLAY_SESSION=$(nice_ellipsis "$DISPLAY_SESSION" 5)
			else
				TMUX_USER=$(nice_ellipsis "$TMUX_USER" 3)
				DISPLAY_SESSION=$(nice_ellipsis "$DISPLAY_SESSION" 5)
			fi
		fi
		# mode text only if it fits
		if [ "$COLUMNS" -ge 80 ]; then
			LEFT_STATUS="$LEFT_STATUS$MODE_WORD$S_STATUS_DIV_L"
		else
			LEFT_STATUS="$LEFT_STATUS#[$STYLE_STATUS_L]"
		fi
		LEFT_STATUS="$LEFT_STATUS$TMUX_USER@$TMUX_HOST$S_STATUS_DIV_L$DISPLAY_SESSION$S_STATUS_L_END"
	fi
	if [ "$__sp_tmux_ver" -ge 203 ]; then
		# always output the format variable
		if echo ",$CLIENT_FEATURES," | grep -q ",focus," && ! echo ",$CLIENT_FLAGS," | grep -q ",focused,"; then
			# if the client terminal supports focus reporting and is currently absent, stop updating the status
			:
		else
			t set -qg '@left_status' "$LEFT_STATUS"
		fi
		echo "#{@left_status}"
	else
		echo "$LEFT_STATUS"
	fi

}

# set BATTERY to charge (e.g. "87%" or "87%+" while charging) if a battery
# is present and not fully charged; set to nothing otherwise (no battery,
# or battery at 100%)
assign_battery() {
	BATTERY=
	POWERED=0
	CHARGING=0
	if [ -d /sys/class/power_supply ]; then
		for BAT in /sys/class/power_supply/BAT*; do
			if [ -f "$BAT/capacity" ]; then
				CAPACITY=$(cat "$BAT/capacity" 2>/dev/null)
				if [ -n "$CAPACITY" ] && [ "$CAPACITY" -lt 100 ] 2>/dev/null; then
					if [ "$(cat "$BAT/status" 2>/dev/null)" = "Charging" ]; then
						POWERED=1
						CHARGING=1
					else
						POWERED=0
						CHARGING=0
					fi
				fi
				break
			fi
		done
		if [ -f "/sys/class/power_supply/AC/online" ] && [ "$(cat "/sys/class/power_supply/AC/online")" = 1 ]; then
			POWERED=1
		fi
	elif command -v pmset >/dev/null 2>&1; then
		# macOS
		PMSET_OUT=$(pmset -g batt 2>/dev/null)
		CAPACITY=$(echo "$PMSET_OUT" | sed -n 's/.*[^0-9]\([0-9]\{1,3\}\)%.*/\1/p' | head -n 1)
		if echo "$PMSET_OUT" | grep -q "AC Power"; then
			POWERED=1
		else
			POWERED=0
		fi
		if echo "$PMSET_OUT" | grep -q "; charging"; then
			CHARGING=1
		else
			CHARGING=0
		fi
	else
		return
	fi

	if [ -n "$CAPACITY" ] && [ "$CAPACITY" -lt 100 ] 2>/dev/null; then
		if [ "$CHARGING" = 1 ]; then
			if [ "$LC_NERDLEVEL" -ge 3 ] && [ "$CLOCK_DETAILS" != "1" ]; then
				# charging battery icons
				if [ "$CAPACITY" -gt 99 ]; then
					BATICON="󰂅"
				elif [ "$CAPACITY" -gt 90 ]; then
					BATICON="󰂋"
				elif [ "$CAPACITY" -gt 80 ]; then
					BATICON="󰂊"
				elif [ "$CAPACITY" -gt 70 ]; then
					BATICON="󰢞"
				elif [ "$CAPACITY" -gt 60 ]; then
					BATICON="󰂉"
				elif [ "$CAPACITY" -gt 50 ]; then
					BATICON="󰢝"
				elif [ "$CAPACITY" -gt 40 ]; then
					BATICON="󰂈"
				elif [ "$CAPACITY" -gt 30 ]; then
					BATICON="󰂇"
				elif [ "$CAPACITY" -gt 20 ]; then
					BATICON="󰂆"
				elif [ "$CAPACITY" -gt 10 ]; then
					BATICON="󰢜"
				else
					BATICON="󰢟"
				fi
				BATTERY="$BATICON"
			else
				# charging battery text
				BATTERY="${CAPACITY}%+"
			fi
		else
			if [ "$LC_NERDLEVEL" -ge 3 ] && [ "$CLOCK_DETAILS" != "1" ]; then
				# discharging battery icons
				if [ "$CAPACITY" -gt 99 ]; then
					BATICON="󰁹"
				elif [ "$CAPACITY" -gt 90 ]; then
					BATICON="󰂂"
				elif [ "$CAPACITY" -gt 80 ]; then
					BATICON="󰂁"
				elif [ "$CAPACITY" -gt 70 ]; then
					BATICON="󰂀"
				elif [ "$CAPACITY" -gt 60 ]; then
					BATICON="󰁿"
				elif [ "$CAPACITY" -gt 50 ]; then
					BATICON="󰁾"
				elif [ "$CAPACITY" -gt 40 ]; then
					BATICON="󰁽"
				elif [ "$CAPACITY" -gt 30 ]; then
					BATICON="󰁼"
				elif [ "$CAPACITY" -gt 20 ]; then
					BATICON="󰁻"
				elif [ "$CAPACITY" -gt 10 ]; then
					BATICON="󰁺"
				else
					BATICON="󱃍"
				fi
				BATTERY="$BATICON"
			else
				# discharging battery text
				BATTERY="${CAPACITY}%"
			fi
			
			# not charging but powered state
			if [ "$POWERED" = 1 ]; then
				if [ "$LC_NERDLEVEL" -ge 3 ] && [ "$CLOCK_DETAILS" != "1" ]; then
					BATTERY="$BATTERY="
				else
					BATTERY="$BATTERY="
				fi
			fi
		fi
	fi
}

right_status() {
	if [ "${1:-}" = "" ]; then
		CLOCK_DETAILS="$(tmux show -gqv @clock_details)"
		COLUMNS="$(tmux display -p '#{window_width}')"
		CLIENT_FLAGS="$(tmux display -p '#{client_flags}')"
		CLIENT_FEATURES="$(tmux display -p '#{client_termfeatures}')"
	else
		CLOCK_DETAILS="$1"
		COLUMNS="$2"
		CLIENT_FLAGS="$3"
		CLIENT_FEATURES="$4"
	fi
	if [ "$CLOCK_DETAILS" = "2" ]; then
		# collapsed mode
		SILENT_STATUS="#[$STYLE_STATUS_R]$S_STATUS_R_BEGIN$S_COLLAPSED_R"
		echo "$SILENT_STATUS"
		return
	elif echo ",$CLIENT_FEATURES," | grep -q ",focus," && ! echo ",$CLIENT_FLAGS," | grep -q ",focused,"; then
		# if the client terminal supports focus reporting and is currently absent, stop updating the status
		:
	elif [ "$COLUMNS" -ge 100 ]; then
		# wide terminal
		LOADAVG=$( ([ -f /proc/loadavg ] && cut -d " " -f -3 /proc/loadavg) || sysctl vm.loadavg 2>/dev/null | sed "s/.*{ //;s/ }.*//" )
		assign_battery
		[ "$BATTERY" = "" ] || BATTERY="$BATTERY$S_STATUS_DIV_R"
		if [ "$CLOCK_DETAILS" = "1" ]; then
			# long format
			CLOCK=$(date '+%Y-%m-%dT%H:%M:%S%z')
		else
			# short format
			CLOCK="$(date '+%b-%d') $(date '+%H:%M')"
			if [ "$COLUMNS" -lt 120 ]; then
				LOADAVG=$(echo "$LOADAVG" | cut -d " " -f 1)
			fi
		fi
		t set -qg @right_status "#[$STYLE_STATUS_R]$S_STATUS_R_BEGIN$BATTERY$LOADAVG$S_STATUS_DIV_R$CLOCK"
	else
		# narrow terminal: no details
		CLOCK=$(date '+%H:%M')
		assign_battery
		[ "$BATTERY" = "" ] || BATTERY="$BATTERY$S_STATUS_DIV_R"
		t set -qg @right_status "#[$STYLE_STATUS_R]$S_STATUS_R_BEGIN$BATTERY$CLOCK"
	fi
	if [ "$__sp_tmux_ver" -ge 203 ]; then
		# always output the format variable
		echo "#{@right_status}"
	else
		t_flush
		format="$(tmux show -gqv @right_status)"
		echo "$format"
	fi
}

toggle_host_details() {
	if [ "${1:-}" = "" ]; then
		HOST_DETAILS="$(tmux show -gqv @host_details)"
	else
		HOST_DETAILS="$1"
	fi
	if [ "$HOST_DETAILS" = "2" ]; then
		t set -g '@host_details' 0
	elif [ "$HOST_DETAILS" = "1" ]; then
		t set -g '@host_details' 2
	else
		t set -g '@host_details' 1
	fi
	legacy_force_status_update
}

toggle_clock_details() {
	if [ "${1:-}" = "" ]; then
		CLOCK_DETAILS="$(tmux show -gqv @clock_details)"
	else
		CLOCK_DETAILS="$1"
	fi
	if [ "$CLOCK_DETAILS" = "2" ]; then
		t set -g '@clock_details' 0
		t refresh-client -S
		t set -g status-interval "$D_STATUS_INTERVAL"
		t refresh-client -S
	elif [ "$CLOCK_DETAILS" = "1" ]; then
		t set -g '@clock_details' 2
		t set -g status-interval "$D_STATUS_INTERVAL"
	else
		t set -g '@clock_details' 1
		# when showing details, switch to refresh each second
		t set -g status-interval 1
	fi
	legacy_force_status_update
}

toggle_zen_mode() {
	if [ "$(tmux show -gqv @clock_details)" != "2" ] || [ "$(tmux show -gqv @host_details)" != "2" ]; then
		t set -g '@clock_details' 2
		t set -g '@host_details' 2
	else
		t set -g '@clock_details' 0
		t set -g '@host_details' 0
		t set -g status-interval "$D_STATUS_INTERVAL"
	fi
	legacy_force_status_update
}

client_attached() {
	# simply repeat execution of main on attach
	main
}

# apply custom overrides
custom_functions

SUBCOMMAND="$1"
shift
"$SUBCOMMAND" "$@"

exit
}