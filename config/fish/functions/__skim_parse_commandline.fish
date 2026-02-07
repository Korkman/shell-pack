# __skim_* functions credit: https://github.com/skim-rs/skim/

function __skim_parse_commandline -d 'Parse the current command line token and return split of existing filepath and rest of token'
	# eval is used to do shell expansion on paths
	set -l commandline (eval "printf '%s' "(commandline -t))

	if [ -z $commandline ]
		# Default to current directory with no --query
		set dir '.'
		set skim_query ''
	else
		set dir (__skim_get_dir $commandline)

		if [ "$dir" = "." -a (string sub -l 1 -- $commandline) != '.' ]
			# if $dir is "." but commandline is not a relative path, this means no file path found
			set skim_query $commandline
		else
			# Also remove trailing slash after dir, to "split" input properly
			set skim_query (string replace -r "^$dir/?" -- '' "$commandline")
		end
	end

	echo $dir
	echo $skim_query
end

function __skim_get_dir -d 'Find the longest existing filepath from input string'
	set dir $argv

	# Strip all trailing slashes. Ignore if $dir is root dir (/)
	if [ (string length -- $dir) -gt 1 ]
		set dir (string replace -r '/*$' -- '' $dir)
	end

	# Iteratively check if dir exists and strip tail end of path
	while [ ! -d "$dir" ]
		# If path is absolute, this can keep going until ends up at /
		# If path is relative, this can keep going until entire input is consumed, dirname returns "."
		set dir (dirname -- "$dir")
	end

	echo $dir
end