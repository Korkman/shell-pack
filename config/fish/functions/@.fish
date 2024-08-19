function @ \
	-d 'Execute command at a given time as if typed into the prompt (delay implemented in prompt)'
	set command_and_args $argv[2..-1]
	$command_and_args
end
