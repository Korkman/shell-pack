function timeout -d \
	"timeout wrapper for portability and workaround uutils bug"
	# Prefer gnu coreutils timeout over uutils timeout to improve performance ("timeout date" took 100ms)'
	# see https://github.com/uutils/coreutils/issues/11615
	
	if command -q gnutimeout
		command gnutimeout $argv
	else if command -q timeout
		if $__cap_timeout_has_t
			# ancient busybox requires -t
			command timeout -t $argv
		else
			command timeout $argv
		end
	else
		# timeout is unavailable — parse and ignore its arguments, run the command without a time limit
		argparse -s 'foreground' 'k/kill-after=' 's/signal=' 'v/verbose' 'preserve-status' -- $argv
		# $argv now contains [DURATION] COMMAND [ARG]...
		# skip the leading duration argument
		set -e argv[1]
		command $argv
	end
end
