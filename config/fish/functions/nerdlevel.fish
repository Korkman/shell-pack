function nerdlevel -d "Adjust font symbols or leave FISH shell"
	
	if ! set -q argv[1] || test $argv[1] = "--help"
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
		tmux set-env LC_NERDLEVEL $argv[1]
	end
	if [ "$LC_NERDLEVEL" = "0" ]
		set -g SHELL $OLDSHELL
		if set -q TMUX
			echo "tmux note: new windows will start at LC_NERDLEVEL 0, existing will downgrade to 1"
			tmux set-env LC_NERDLEVEL 0
			tmux set-env SHELL "$OLDSHELL"
		end
		# for some reason wezterm closes the tab when env isn't used
		exec env $OLDSHELL -l
	end

	# old concept: protect LC_NERDLEVEL from tmux env updates
	#if set -q TMUX && contains -- LC_NERDLEVEL $__mmux_imported_environment
	#	echo "LC_NERDLEVEL is now excluded from tmux environment updates!"
	#	set -l i (contains -i -- LC_NERDLEVEL $__mmux_imported_environment)
	#	set -e __mmux_imported_environment[$i]
	#end
	
	fish_greeting
end

