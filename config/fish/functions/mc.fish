function mc -d \
	"a sad hack to force mc detect mouse"
	# a sad hack to force mc detect mouse: add DISPLAY and TERM=screen-256color
	# also: for certain versions of fish, revert to $OLDSHELL for mc subshell
	
	# proxy functions may pass mcview, mcedit, mcdiff here
	set --unexport --local __sp_mc_bin "$__sp_mc_bin"
	if test "$__sp_mc_bin" = ""
		set __sp_mc_bin "mc"
	end
	
	set --local MC_TERM "$TERM"
	if test "$MC_TERM" = "tmux-256color"
		# workaround for older mc versions
		# fixed in Debian Bookworm: mouse works in mc with TERM=tmux-256color
		set MC_TERM "screen-256color"
	end
	
	set --local MC_DISPLAY "$DISPLAY"
	if test "$MC_DISPLAY" = ""
		# workaround for older mc versions
		# fixed in Debian Bookworm: mouse works in mc without setting DISPLAY
		set MC_DISPLAY "_"
	end
	
	if test "$__sp_brave_mc_subshell" = ""
		# set the default for fish as mc subshell to "no" for fish versions 3.3.0 through 3.6.0
		# (when my wonky "TERM dumb" workaround has to be applied)
		if test (__sp_vercmp "$FISH_VERSION" '3.3.0') -ge 0 -a (__sp_vercmp "$FISH_VERSION" '3.6.1') -lt 0
			set __sp_brave_mc_subshell no
		else
			set __sp_brave_mc_subshell yes
		end
	end
	
	set --local MC_NERDLEVEL $LC_NERDLEVEL
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
	
	# NOTE: this is fixed in mc for Debian Bookworm, but we're supporting Stretch here
	# __sp_mc_launcher only handles plain, argument-less "mc" (it enables the
	# sudo-elevation toggle menu entry); mcview/mcedit/mcdiff and any mc
	# invocation with arguments bypass it and run the binary directly
	if ! fish_is_root_user; and [ "$__sp_mc_bin" = "mc" ]; and [ (count $argv) -eq 0 ]
		env DISPLAY=$MC_DISPLAY TERM=$MC_TERM LC_NERDLEVEL=$MC_NERDLEVEL __sp_mc_launcher
	else
		env DISPLAY=$MC_DISPLAY TERM=$MC_TERM LC_NERDLEVEL=$MC_NERDLEVEL $__sp_mc_bin $argv
	end
end
