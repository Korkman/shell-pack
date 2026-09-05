function __sp_http
	argparse 't/timeout=?' -- $argv
	if test -z "$_flag_t"
		set timeout 10
	else
		set timeout $_flag_t
	end
	
	if type -q curl
		curl --max-time $timeout --location --max-redirs 10 --retry 0 --fail --silent "$argv[1]"
	else if type -q wget
		set -l wget wget --timeout=$timeout -q -O-
		if $__cap_wget_has_max_redirect
			set -a wget --max-redirect=10
		end
		$wget "$argv[1]"
	else
		# this function is compatible with wget2
		echo "Error: Neither curl nor wget/wget2 is installed." >&2
		return 1
	end
end
