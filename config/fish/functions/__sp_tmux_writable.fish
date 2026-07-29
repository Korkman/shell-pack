function __sp_tmux_writable -d \
	"Determine whether the tmux socket is writable for us"
	if set -q TMUX && test -w (string replace -r ',.*' '' $TMUX)
		return 0
	else
		return 1
	end
end
