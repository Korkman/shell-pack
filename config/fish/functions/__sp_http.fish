function __sp_http
	argparse 't/timeout=?' -- $argv
	test "$timeout" != "" || set timeout 10
	
	if command -q curl
		curl --max-time $timeout --location --max-redirs 10 --retry 0 --fail --silent "$argv[1]"
	else if command -q wget
		wget --timeout $timeout --max-redirect 10 --quiet -O- "$argv[1]"
	else
		echo "Error: Neither curl nor wget is installed." >&2
		return 1
	end
end
