function localsend-cli -d "LocalSend CLI wrapper with on-demand installation"
	# parse $argv but restore it afterwards
	set -l argv_copy $argv
	argparse -i 'h/help' 'V/version' -- $argv
	set argv $argv_copy
	
	if not command -q localsend-cli
		__sp_test_product_version "localsend-cli" "1.18.2" "localsend-cli --version" "Run: shell-pack-deps install localsend-cli v\$minver"
		or return $status
	end

	if command -q localsend-cli
		# if help isn't requested anyways, print out the hotkeys as a reminder
		if ! set -q _flag_help && ! set -q _flag_version
			command localsend-cli --help | awk '/Environment Variables/{exit} /Hotkeys/{flag=1} flag'
		end
		command localsend-cli $argv
	else
		return 1
	end
end
