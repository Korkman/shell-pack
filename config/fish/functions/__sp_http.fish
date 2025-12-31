function __sp_http
	argparse 't/timeout=?' -- $argv
	if test -z "$_flag_t"
		set timeout 10
	else
		set timeout $_flag_t
	end
	if command -q curl
		curl --max-time $timeout --location --max-redirs 10 --retry 0 --fail --silent "$argv[1]"
	else if command -q wget
		wget --timeout $timeout --max-redirect 10 --quiet -O- "$argv[1]"
	else
		echo "Error: Neither curl nor wget is installed." >&2
		return 1
	end
end
