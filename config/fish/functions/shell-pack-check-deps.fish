function shell-pack-check-deps -d \
	"Test if dependencies are up-to-date"
	if [ "$UPGRADE_SHELLPACK" = "no" ]
		echo "Upgrade functions disabled"
		return 1
	end
	
	if ! set -q __sp_first_startup_done
		echo "This seems to be your first time using shell-pack."
		echo "Installing dependencies ..."
		if command -q fzf
			echo "Fzf pre-installed, skipping ..."
		else
			shell-pack-deps install fzf
		end
		if command -q rg
			echo "Ripgrep pre-installed, skipping ..."
		else
			shell-pack-deps install ripgrep
		end
		if command -a dool | string match -v --regex "^"(string escape --style regex -- $__sp_dir)"/bin/dool" &> /dev/null
		   or [ -e "$__sp_dir/bin/dool.d/dool" ]
		   	# a dool which is not shell-pack's wrapper exists or the dool.d directory already exists
			echo "Dool pre-installed, skipping ..."
		else
			shell-pack-deps install dool
		end
		reinstall-shell-pack-prefs
		set --universal __sp_first_startup_done 1
	end
	
	set __shp_outdated_deps ""
		
	__sp_test_product_version "ripgrep" "15.2.0" "rg --version"       "Run: shell-pack-deps install ripgrep \$minver"
	__sp_test_product_version "fzf"     "0.74.3" "fzf --version"      "Run: shell-pack-deps install fzf \$minver"
	__sp_test_product_version "fish"    "3.5.1"  "fish --version"     "Run: upgrade-fish"
	# skip dool if python3 is not present or outdated
	if command -q python3 && __sp_test_product_version "python3" "3.6.0" "python3 --version"
		__sp_test_product_version "dool"    "1.3.8"  "dool --version"       "Run: shell-pack-deps install dool \$minver"
	end
	__sp_test_product_version "fresh"   "0.5.1" "fresh --version"    "Run: shell-pack-deps install fresh v\$minver"
	__sp_test_product_version "bat"     "0.26.1"  "bat --version"     "Run: shell-pack-deps install bat \$minver"
	
	if test "$__shp_outdated_deps" != ""
		echo "outdated: $__shp_outdated_deps"
	end
end

