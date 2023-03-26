function __skimcmd
	#set -q SKIM_TMUX; or set SKIM_TMUX 0
	set -q SKIM_TMUX_HEIGHT; or set SKIM_TMUX_HEIGHT 40%
	#if [ $SKIM_TMUX -eq 1 ]
	#	echo "sk-tmux -d$SKIM_TMUX_HEIGHT"
	#else
	#	echo "sk"
	#end
	
	#echo "sk"
	# fzf will not escape {} properly ("text\" becomes 'text\' <- this is invalid in fish )
	# using tolerance from /bin/sh to workaround
	set -x SHELL '/bin/sh'
	echo "fzf"
end
