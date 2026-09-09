function shell-pack-deps -d \
	"Perform various actions to manage dependencies"
	if test "$argv[1]" = "check"
		shell-pack-check-deps
	else if test "$argv[1]" = "install"
		if test "$argv[2]" = "fzf"
			__sp_deps_install_fzf $argv[3] || echo "Failed with status $status"
		else if test "$argv[2]" = "ripgrep"
			__sp_deps_install_ripgrep $argv[3] || echo "Failed with status $status"
		else if test "$argv[2]" = "dool"
			__sp_deps_install_dool $argv[3] || echo "Failed with status $status"
		else if test "$argv[2]" = "fresh"
			__sp_deps_install_fresh $argv[3] || echo "Failed with status $status"
		else if test "$argv[2]" = "bat"
			__sp_deps_install_bat $argv[3] || echo "Failed with status $status"
		else if test "$argv[2]" = "localsend-cli"
			__sp_deps_install_localsend_cli $argv[3] || echo "Failed with status $status"
		else
			echo "Invalid argument"
			return 2
		end
	else
		echo "Invalid argument"
		return 1
	end
end








