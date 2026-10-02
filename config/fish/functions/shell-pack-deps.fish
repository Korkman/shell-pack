function shell-pack-deps -d \
	"Perform various actions to manage dependencies"
	if test "$argv[1]" = "check" || test "$argv[1]" = ""
		__sp_deps_check
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
	else if test "$argv[1]" = "minimum"
		switch "$argv[2]"
			case ripgrep
				echo "15.2.0"
			case fzf
				# the development version of fzf compiles to "0.xx (devel)", relevant on termux
				echo "0.74"
			case dool
				echo "1.3.8"
			case fresh
				echo "0.5.1"
			case bat
				echo "0.26.1"
			case localsend-cli
				echo "1.18.2"
			case '*'
				echo "unknown"
				return 1
		end
	else if test "$argv[1]" = "recommended"
		switch "$argv[2]"
			case fzf
				echo "0.74.4"
			case localsend-cli
				echo "latest"
			case '*'
				echo (shell-pack-deps minimum "$argv[2]")
		end
	else
		echo "Usage: shell-pack-deps [check|install|minimum|recommended]"
		echo "  check              - check if dependencies are up-to-date"
		echo "  install <pkg> [v]  - install <pkg> at version [v] (or recommended)"
		echo "  minimum <pkg>      - show minimum required version"
		echo "  recommended <pkg>  - show recommended version"
		return 1
	end
end

function __sp_deps_check -d \
	"Test if dependencies are up-to-date"
	if [ "$UPGRADE_SHELLPACK" = "no" ]
		echo "Upgrade functions disabled"
		return 1
	end
	
	if ! set -q __sp_first_startup_done
		echo "This seems to be your first time using shell-pack. Welcome!"
		echo "You can repeat this setup at any time by invoking 'shell-pack-deps check'."
		echo "Please take a minute to confirm or reject the following steps."
		echo
		shell-pack-prefs install
		set --universal __sp_first_startup_done 1
	end
	
	set __shp_outdated_deps ""
	
	__sp_test_product_version "ripgrep" (shell-pack-deps minimum ripgrep) "rg --version"       "Run: shell-pack-deps install ripgrep "(shell-pack-deps recommended ripgrep)
	__sp_test_product_version "fzf"     (shell-pack-deps minimum fzf) "fzf --version"      "Run: shell-pack-deps install fzf "(shell-pack-deps recommended fzf)
	__sp_test_product_version "fish"    "3.5.1"  "fish --version"     "Run: shell-pack-upgrade fish"
	# skip dool if python3 is not present or outdated
	if command -q python3 && __sp_test_product_version "python3" "3.6.0" "python3 --version"
		__sp_test_product_version "dool"    (shell-pack-deps minimum dool) "dool --version"       "Run: shell-pack-deps install dool "(shell-pack-deps recommended dool)
	end
	__sp_test_product_version "fresh"   (shell-pack-deps minimum fresh) "fresh --version"    "Run: shell-pack-deps install fresh v"(shell-pack-deps recommended fresh)
	__sp_test_product_version "bat"     (shell-pack-deps minimum bat)  "bat --version"     "Run: shell-pack-deps install bat "(shell-pack-deps recommended bat)
	
	if test "$__shp_outdated_deps" != ""
		echo "outdated: $__shp_outdated_deps"
	end
	
end
