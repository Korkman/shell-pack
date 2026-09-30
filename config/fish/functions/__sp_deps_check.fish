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
