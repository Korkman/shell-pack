function mc -d \
	"a sad hack to force mc detect mouse"
	set --local MC_NERDLEVEL $LC_NERDLEVEL
	if [ "$__sp_brave_mc_subshell" = "no" ]
		# not enabled
		
		# pass OLDSHELL as SHELL to mc
		if test "$OLDSHELL" != ""
			# newer versions of nerdlevel.sh pass the default SHELL in OLDSHELL
			set --export SHELL $OLDSHELL
		end
		
		#echo -n "Starting mc with SHELL=$SHELL - 'set --universal __sp_brave_mc_subshell 1' to run with fish"
		set MC_NERDLEVEL 0
	end
	
	# a sad hack to force mc detect mouse: add DISPLAY to screen-256color
	env DISPLAY=_ LC_NERDLEVEL=$MC_NERDLEVEL mc $argv
end
