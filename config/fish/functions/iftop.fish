function iftop -d \
	"fix iftop in tmux (TERM)"
	if test "$TERM" = "tmux-256color"
		env TERM=xterm-256color iftop $argv
	else if test "$TERM" = "tmux"
		env TERM=xterm iftop $argv
	else
		command iftop $argv
	end
end
