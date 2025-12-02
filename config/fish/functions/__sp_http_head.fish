function __sp_http_head
	argparse 't/timeout=?' -- $argv
	test "$timeout" != "" || set timeout 10
	
	if command -q curl
		curl --max-time $timeout --head --location --max-redirs 10 --retry 0 --fail --silent "$argv[1]"
	else if command -q wget
		wget --timeout $timeout --method=HEAD --max-redirect 10 --server-response --quiet -O- "$argv[1]"
	else
		echo "Error: Neither curl nor wget is installed." >&2
		return 1
	end
end
