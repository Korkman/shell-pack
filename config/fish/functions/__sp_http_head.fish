function __sp_http_head
	argparse 't/timeout=?' -- $argv
	if test -z "$_flag_t"
		set timeout 10
	else
		set timeout $_flag_t
	end
	
	if type -q curl
		curl -o /dev/null -D - --max-time $timeout --location --max-redirs 10 --retry 0 --fail --silent "$argv[1]"
	else if type -q wget && ! wget --help &| string match -q "GNU Wget2*"
		# classic wget writes --server-response headers to stderr
		set -l wget wget -O /dev/null --server-response --timeout=$timeout -q
		if $__cap_wget_has_max_redirect
			set -a wget --max-redirect=10
		end
		$wget "$argv[1]" 2>&1
	else
		# this function is not compatible with wget2. making it work is non-trivial.
		# TODO: implement wget2 compatibility
		echo "Error: Neither curl nor wget 1.x is installed." >&2
		return 1
	end
end
