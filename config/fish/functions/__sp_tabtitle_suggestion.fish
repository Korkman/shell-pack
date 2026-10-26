function __sp_tabtitle_suggestion -d \
	'Propose a tab title; --restore pops the previous one, --force skips weighing against the current title. Keeps the current title if it is more meaningful'
	argparse 'r/restore' 'f/force' -- $argv
	or return

	# fast exit when no TMUX is present (fetching current tabtitle from screen not implemented)
	set -q TMUX || return
	
	# make sure __update_tab_title is loaded (for when called from non-fish shells)
	functions -q fish_title

	if set -q _flag_restore
		set -q __sp_tabtitle_stack[1]
		or return
		set -l previous $__sp_tabtitle_stack[-1]
		set -e __sp_tabtitle_stack[-1]
		set -g tabtitle $previous
		return
	end

	set -l proposed (string trim -- "$argv[1]")

	# the tmux window name is authoritative: it also reflects titles set by
	# other processes, while $tabtitle is only known to this shell
	set -l current
	if set -q tabtitle
		set current "$tabtitle"
	else if command -q tmux
		set -l target
		set -q TMUX_PANE
		and set target -t $TMUX_PANE
		set -l tmux_title (tmux display-message -p $target '#W' 2>/dev/null)
		and set current "$tmux_title"
	else
		# TMUX set but command missing, very funny
		return
	end

	# always push, so every call can be balanced by --restore
	set -g __sp_tabtitle_stack $__sp_tabtitle_stack "$current"

	test -n "$proposed"
	or return

	if set -q _flag_force
		set -g tabtitle "$proposed"
		return
	end

	# reduce to the command name: strip "!" status and "#tag " session prefixes
	set -l current_cmd (string replace -r '^!' '' -- "$current" | string replace -r '^#\S+\s*' '' | string split -f1 ' ')
	set current_cmd (path basename "$current_cmd")

	# Only titles of idle shells, file managers and generic wrappers give way.
	# Anything else (man, systemctl, journalctl, ppage, grasp, ...) is assumed
	# to describe the user's activity better than the helper started by it.
	switch "$current_cmd"
		case '' ppage grasp fish sh bash dash zsh ksh mc mcedit mcview \
			sudo su doas env nice ionice timeout nohup setsid xargs watch script
			set -g tabtitle "$proposed"
	end
end
