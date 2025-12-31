function __sp_http_head
	argparse 't/timeout=?' -- $argv
	if test -z "$_flag_t"
		set timeout 10
	else
		set timeout $_flag_t
	end
	
	if command -q curl
		curl -o /dev/null -D - --max-time $timeout --location --max-redirs 10 --retry 0 --fail --silent "$argv[1]"
	else if command -q wget
		wget -O /dev/null --server-response --timeout $timeout --max-redirect 10 --quiet "$argv[1]" 2>&1
	else
		echo "Error: Neither curl nor wget is installed." >&2
		return 1
	end
end
