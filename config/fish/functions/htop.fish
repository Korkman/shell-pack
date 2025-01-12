function htop -d \
	"a sad hack to fix htop shift-tab"
	if test "$TERM" = "tmux"
		set FAKETERM "xterm"
	else if test "$TERM" = "tmux-256color"
		set FAKETERM "xterm-256color"
	else
		set FAKETERM "$TERM"
	end
	TERM="$FAKETERM" command htop $argv
end
