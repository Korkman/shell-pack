function mcedit -d \
	"a sad hack to force mc detect mouse"
	if test "$DISPLAY" = ""
		# a sad hack to make mc detect mouse: add DISPLAY to screen-256color
		env DISPLAY=_ mcedit $argv
	else
		env mcedit $argv
	end
end
