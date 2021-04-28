function nerdlevel
	if ! set -q argv[1]
		echo "Usage: nerdlevel LEVEL"
		echo
		echo "  Set nerdlevel to LEVEL (0-3)"
		echo
		return 1
	end
	set -g LC_NERDLEVEL $argv[1]
	if set -q TMUX
		# new concept: broadcast new nerdlevel to all tmux
		echo "tmux note: new and existing windows will inherit new LC_NERDLEVEL"
		tmux set-env LC_NERDLEVEL $argv[1]
	end
	if [ "$LC_NERDLEVEL" = "0" ]
		set -g SHELL /bin/bash
		if set -q TMUX
			echo "tmux note: new windows will start at LC_NERDLEVEL 0, existing will downgrade to 1"
			tmux set-env LC_NERDLEVEL 0
			tmux set-env SHELL /bin/bash
		end
		exec bash -l
	end

	# old concept: protect LC_NERDLEVEL from tmux env updates
	#if set -q TMUX && contains -- LC_NERDLEVEL $__mmux_imported_environment
	#	echo "LC_NERDLEVEL is now excluded from tmux environment updates!"
	#	set -l i (contains -i -- LC_NERDLEVEL $__mmux_imported_environment)
	#	set -e __mmux_imported_environment[$i]
	#end
	
	fish_greeting
end

