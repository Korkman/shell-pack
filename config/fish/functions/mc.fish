function mc -d \
	"a sad hack to force mc detect mouse"
	set --local MC_NERDLEVEL $LC_NERDLEVEL
	# mc subshell control is badly inconsistent and outright broken on many installs
	# export a more simple $SHELL ($OLDSHELL should be bash or zsh) for mc
	# unless $__sp_brave_mc_subshell explcitly enables fish
	if [ "$__sp_brave_mc_subshell" != "yes" ]
		
		# pass OLDSHELL as SHELL to mc
		if test "$OLDSHELL" != ""
			# newer versions of nerdlevel.sh pass the default SHELL in OLDSHELL
			set --export SHELL $OLDSHELL
		else
			# bash as fallback
			set --export SHELL (command -v bash)
		end
		
		set MC_NERDLEVEL 0
	end
	
	# a sad hack to force mc detect mouse: add DISPLAY to screen-256color
	env DISPLAY=_ LC_NERDLEVEL=$MC_NERDLEVEL mc $argv
end
