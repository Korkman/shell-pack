function mc \
-d "Run midnight commander with $OLDSHELL subshell to stabilize it"
	set --local --export SHELL $SHELL
	if ! set -q __sp_brave_mc_subshell || [ "$__sp_brave_mc_subshell" = "0" ]
		# not enabled
		if test "$OLDSHELL" != ""
			# newer versions of nerdlevel.sh pass the default SHELL in OLDSHELL
			set SHELL $OLDSHELL
		else
			# otherwise, guess shell from installed
			if set SHELL (which bash)
			else if set SHELL (which zsh)
			else
				# last resort, sh
				set SHELL (which sh)
			end
		end
		
		#echo -n "Starting mc with SHELL=$SHELL - 'set --universal __sp_brave_mc_subshell 1' to run with fish"
		env LC_NERDLEVEL=0 mc $argv
	else
		command mc $argv
	end

end
