function __skimcmd
	set -q SKIM_TMUX; or set SKIM_TMUX 0
	set -q SKIM_TMUX_HEIGHT; or set SKIM_TMUX_HEIGHT 40%
	if [ $SKIM_TMUX -eq 1 ]
		echo "sk-tmux -d$SKIM_TMUX_HEIGHT"
	else
		echo "sk"
	end
end
