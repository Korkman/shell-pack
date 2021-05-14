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
			echo "Skim pre-installed, skipping ..."
		else
			shell-pack-deps install fzf
		end
		if command -q rg
			echo "Ripgrep pre-installed, skipping ..."
		else
			shell-pack-deps install ripgrep
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
		
		if set version_found (string match --regex '([0-9]+(\.[0-9]+){1,3})' "$version_in_there")
			set version_found "$version_found[1]"
			set dec_version_found (printf "%d" (get_hex_from_version "$version_found"))
		else
			set version_found "n/a"
			set dec_version_found 0
		end
		set dec_version_required (printf "%d" (get_hex_from_version "$minver"))
		
		if test "$dec_version_found" -lt "$dec_version_required"
			set __shp_outdated_deps "$__shp_outdated_deps $product"
			set -l product_url (string replace '$minver' "$minver" -- "$product_url")
			echo "NOTE: $product is outdated - $version_found < $minver"
			echo "$product_url"
		end
	end
	
	function get_hex_from_version
		set verparts (string split . $argv[1])
		while test (count $verparts) -lt 4
			set verparts $verparts 0
		end
		echo "0x"(printf "%02x" $verparts[1])(printf "%02x" $verparts[2])(printf "%02x" $verparts[3])(printf "%02x" $verparts[4])
	end
	
	test_version_min "ripgrep" "12.1.1" "rg --version"       "Run: shell-pack-deps install ripgrep \$minver"
	test_version_min "fzf"     "0.27.0" "fzf --version"      "Run: shell-pack-deps install fzf \$minver"
	test_version_min "fish"    "3.2.1"  "fish --version"     "See https://fishshell.com/"
	#test_version_min "skim"    "0.9.4"  "sk --version"       "Run: shell-pack-deps install skim \$minver"
	
	functions -e test_version_min
	functions -e get_hex_from_version
	
	if test "$__shp_outdated_deps" != ""
		echo "outdated: $__shp_outdated_deps"
	end
end

