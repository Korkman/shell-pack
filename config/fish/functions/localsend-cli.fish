function localsend-cli -d "LocalSend CLI wrapper with on-demand installation"
	if not command -q localsend-cli
		echo "localsend-cli is not installed."
		__sp_deps_install_localsend_cli; or return $status
	end

	if command -q localsend-cli
		command localsend-cli $argv
	else
		return 1
	end
end
