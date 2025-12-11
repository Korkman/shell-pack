function __sp_http_head
	argparse 't/timeout=?' -- $argv
	test "$timeout" != "" || set timeout 10
	
	if command -q curl
		curl -o /dev/null -D - --max-time $timeout --location --max-redirs 10 --retry 0 --fail --silent "$argv[1]"
	else if command -q wget
		wget -O /dev/null --server-response --timeout $timeout --max-redirect 10 --quiet "$argv[1]" 2>&1
	else
		echo "Error: Neither curl nor wget is installed." >&2
		return 1
	end
end
