function mc -d \
	"a sad hack to force mc detect mouse"
	set --local MC_NERDLEVEL $LC_NERDLEVEL
	
	if test "$__sp_brave_mc_subshell" = ""
		# set the default for fish as mc subshell to "no" for fish versions 3.3.0 through 3.6.0
		# (when my wonky "TERM dumb" workaround has to be applied)
		if test (__sp_vercmp "$FISH_VERSION" '3.3.0') -ge 0 -a (__sp_vercmp "$FISH_VERSION" '3.6.1') -lt 0
			set __sp_brave_mc_subshell no
		else
			set __sp_brave_mc_subshell yes
		end
	end
	
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
	if test "$DISPLAY" = ""
		env DISPLAY=_ LC_NERDLEVEL=$MC_NERDLEVEL mc $argv
	else
		env LC_NERDLEVEL=$MC_NERDLEVEL mc $argv
	end
end
