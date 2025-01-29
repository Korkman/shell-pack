function __sp_require_cmd
	type -q "$argv[1]" && return 0
	echo "Required command missing: $argv[1]"
	return 1
end
