function td-test-qssh -d \
	"Populate qssh with a few local hosts by briefly connecting to them"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td test-qssh"
		echo
		echo "  Runs qssh against 127.1, 127.2 and 127.3 for one second each,"
		echo "  so that its host history has entries to try out."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	need --ask ssh; or return 1

	for host in 127.1 127.2 127.3
		timeout 1 qssh $host &
	end
	wait
end
