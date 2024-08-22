function __force_redraw_prompt
	# move cursor up
	echo -en '\033[1A'
	# move cursor to pos1
	echo -en '\r'
	# clear line
	echo -en (string repeat -n $COLUMNS ' ')
	# move cursor up
	echo -en '\033[1A'
	# draw prompt
	fish_prompt
	# draw cmdline
	echo -n (commandline)
end