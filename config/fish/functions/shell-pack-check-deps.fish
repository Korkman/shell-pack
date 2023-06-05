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
		#if command -q sk
		#	echo "Skim pre-installed, skipping ..."
		#else
		#	shell-pack-deps install skim
		#end
		reinstall-shell-pack-prefs
		set --universal __sp_first_startup_done 1
		return
	end	
	
	set __shp_outdated_deps ""
	
	function test_version_min
		set -l product $argv[1]
		set -l minver $argv[2]
		set -l vercall (string split -- ' ' $argv[3])
		set -l product_url $argv[4]
		
		if command -q "$vercall[1]"
			if ! set version_in_there (eval $vercall)
				set version_in_there "0.0.1"
			end
		else
			set version_in_there "0.0.0"
		end
		
		if set version_found (string match --regex -- '([0-9]+(\.[0-9]+){1,3})' "$version_in_there")
			set version_found "$version_found[1]"
		else
			set version_found "0.0.2"
		end
		
		if test (__sp_vercmp "$version_found" "$minver") -lt 0
			set __shp_outdated_deps "$__shp_outdated_deps $product"
			set -l product_url (string replace '$minver' "$minver" -- "$product_url")
			echo "NOTE: $product is outdated - $version_found < $minver"
			if status --is-interactive && string match -qr '^Run: ' -- "$product_url"
				read -n1 -P "$product_url ? (Y/n)" answer || set answer n
				if test "$answer" != "" && test "$answer" != "y" && test "$answer" != "Y"
					return
				end
				eval (string replace -r '^Run: ' '' -- "$product_url")
			else
				echo "$product_url"
			end
		end
	end
	
	test_version_min "ripgrep" "13.0.0" "rg --version"       "Run: shell-pack-deps install ripgrep \$minver"
	test_version_min "fzf"     "0.38.0" "fzf --version"      "Run: shell-pack-deps install fzf \$minver"
	test_version_min "fish"    "3.2.1"  "fish --version"     "See https://fishshell.com/"
	#test_version_min "skim"    "0.9.4"  "sk --version"       "Run: shell-pack-deps install skim \$minver"
	test_version_min "dool"    "1.2.0"  "dool --version"       "Run: shell-pack-deps install dool \$minver"
	
	functions -e test_version_min
	
	if test "$__shp_outdated_deps" != ""
		echo "outdated: $__shp_outdated_deps"
	end
end

