function nerdlevel -d "Adjust font symbols or leave FISH shell"
	
	if ! set -q argv[1] || test "$argv[1]" = "--help"
		echo "Usage: nerdlevel LEVEL"
		echo
		echo "Enter or leave FISH shell with Shell-Pack, adjust symbol support"
		echo "  0 = return to \$OLDSHELL ($OLDSHELL)"
		echo "  1 = no symbols"
		echo "  2 = powerline font"
		echo "  3 = font awesome"
		return 1
	end >&2
	
	set -g LC_NERDLEVEL $argv[1]
	if set -q TMUX
		# new concept: broadcast new nerdlevel to all tmux
		echo "tmux note: new and existing windows will inherit new LC_NERDLEVEL"
		tmux set-environment LC_NERDLEVEL $argv[1]
		tmux set-environment -g LC_NERDLEVEL $argv[1]
		tmux refresh-client -S
	end
	if [ "$LC_NERDLEVEL" = "0" ]
		set -g SHELL $OLDSHELL
		if set -q TMUX
			echo "tmux note: new windows will start at LC_NERDLEVEL 0, existing will downgrade to 1"
			tmux set-environment LC_NERDLEVEL 0
			tmux set-environment -g LC_NERDLEVEL 0
			tmux set-environment SHELL "$OLDSHELL"
			tmux set-environment -g SHELL "$OLDSHELL"
			tmux set -g default-shell "$OLDSHELL"
			tmux refresh-client -S
		end
		# for some reason wezterm closes the tab when env isn't used
		exec env $OLDSHELL -l
	end

	fish_greeting
end

