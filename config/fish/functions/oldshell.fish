function oldshell \
-d "Convenient access to the system default shell $OLDSHELL"
	if test "$OLDSHELL" = ""
		echo "\$OLDSHELL not set - was nerdlevel.sh sourced in your profile?"
		return
	end
	if test "$OLDSHELL" = (status fish-path)
		echo "It seems your default shell (\$OLDSHELL) is set to fish."
		echo "Therefore, this function is useless to you."
		return
	end
	begin
		# set SHELL for subshells
		set -lx SHELL "$OLDSHELL"
		# unexport TMUX connection in case oldshell has support for
		# importing tmux env, which can cause loops
		set -lu TMUX
		# changing LC_NERDLEVEL without triggering event
		env LC_NERDLEVEL=0 $OLDSHELL $argv
	end
end
