function __sp_deps_install_dool
	if ! command -q python3 || ! __sp_test_product_version "python3" "3.6.0" "python3 --version"
		echo "Python3 missing or < 3.6, skipping dool"
		return
	end
	
	echo "Project website: https://github.com/scottchiefbaker/dool"
	set pversion "$argv[1]"
	if test "$pversion" = ""
		set pversion "1.3.8"
	end
	set url "https://github.com/scottchiefbaker/dool/archive/refs/tags/vVERSION.tar.gz"
	
	set initial_dir "$PWD"
	
	read -P "OK to download and execute release file? (Y/n)" answer || set answer n
	if test "$answer" != "" && test "$answer" != "y" && test "$answer" != "Y"
		return 1
	end
	
	set dldir ~/.cache/shell-pack-downloads
	mkdir -p "$dldir" || return 2
	cd "$dldir" || return 2
	set url (string replace --all 'VERSION' "$pversion" -- "$url")
	
	rm -f dool.tar.gz
	
	echo "Downloading $url ..."
	dl -q "$url" > dool.tar.gz || return 3
	
	cfd dool.tar.gz . || return 4
	
	echo "Installing to ""$__sp_dir""/bin/dool ..."
	cd "dool-""$pversion" || return 5
	rm -rf "$__sp_dir/bin/dool.d"
	mkdir -p "$__sp_dir/bin/dool.d"
	cp "dool" "$__sp_dir/bin/dool.d/dool" || return 51
	cp -a "plugins" "$__sp_dir/bin/dool.d/plugins" || return 52
	
	# NOTE: --groups-only not available in fish 3.3.1, which is the most up-to-date available in rockylinux 9.1
	set new_pversion (dool --version | string match --regex 'Dool ([0-9]\.[0-9]\.[0-9])') | tail -n1 || return 6
	
	echo "Installed version: $new_version"
	
	if ! string match "*$pversion*" -- "$new_pversion"
		echo "Unexpected result, please investigate"
		return 7
	end
	
	echo "Cleaning up ..."
	cd "$initial_dir"
	rm -f "$dldir/dool.tar.gz" || return 8
	rm -rf "$dldir/dool-""$pversion" || return 9
	
	echo "Complete"
end
