function mcdiff -d \
	"a sad hack to force mc detect mouse"
	# a sad hack to make mc detect mouse: add DISPLAY to screen-256color
	env DISPLAY=_ mcdiff $argv
end
