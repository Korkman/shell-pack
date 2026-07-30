function __sp_test_product_version
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
	
	# outdated?
	if test (__sp_vercmp "$version_found" "$minver") -lt 0
		# non-interactive version: return 1
		if test -z "$product_url"
			return 1
		end
		set __shp_outdated_deps "$__shp_outdated_deps $product"
		set -l product_url (string replace '$minver' "$minver" -- "$product_url")
		echo "NOTE: $product is outdated - $version_found < $minver"
		if status --is-interactive && string match -qr '^Run: ' -- "$product_url"
			read -P "$product_url ? (Y/n)" answer || set answer n
			if test "$answer" != "" && test "$answer" != "y" && test "$answer" != "Y"
				return 1
			end
			eval (string replace -r '^Run: ' '' -- "$product_url")
		else
			echo "$product_url"
		end
	end
end
