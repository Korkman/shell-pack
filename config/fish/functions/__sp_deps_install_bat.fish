function __sp_deps_install_bat
	echo "Project website: https://github.com/sharkdp/bat"
	set pversion "$argv[1]"
	if test "$pversion" = ""
		set pversion "0.26.1"
	end
	set tpl_arm_other "https://github.com/sharkdp/bat/releases/download/vVERSION/bat-vVERSION-arm-unknown-linux-gnueabihf.tar.gz"
	set tpl_arm_aarch64 "https://github.com/sharkdp/bat/releases/download/vVERSION/bat-vVERSION-aarch64-unknown-linux-gnu.tar.gz"
	set tpl_x86_64_apple_darwin "https://github.com/sharkdp/bat/releases/download/vVERSION/bat-vVERSION-x86_64-apple-darwin.tar.gz"
	set tpl_x86_64_linux "https://github.com/sharkdp/bat/releases/download/vVERSION/bat-vVERSION-x86_64-unknown-linux-musl.tar.gz"
	
	set initial_dir "$PWD"
	
	if test (uname -m) = "x86_64"
		if test (uname -s) = "Darwin"
			set url "$tpl_x86_64_apple_darwin"
		else
			set url "$tpl_x86_64_linux"
		end
	else if test (uname -m) = "armv6l"
		set url "$tpl_arm_other"
	else if test (uname -m) = "armv7l"
		set url "$tpl_arm_other"
	else if test (uname -m) = "aarch64"
		set url "$tpl_arm_aarch64"
	else
		echo "No matching architecture found, please try downloading yourself"
		return 1
	end
	
	read -P "OK to download and execute release file? (Y/n)" answer || set answer n
	if test "$answer" != "" && test "$answer" != "y" && test "$answer" != "Y"
		return 1
	end
	
	set dldir ~/.cache/shell-pack-downloads
	mkdir -p "$dldir" || return 2
	cd "$dldir" || return 2
	set url (string replace --all 'VERSION' "$pversion" -- "$url")
	
	rm -f bat.tar.gz
	
	echo "Downloading $url ..."
	dl -q "$url" > bat.tar.gz || return 3
	
	cfd bat.tar.gz . || return 4
	
	echo "Installing to ""$__sp_dir""/bin/bat ..."
	cd "bat-v""$pversion""-"* || return 5
	rm -f "$__sp_dir/bin/bat"
	cp "bat" "$__sp_dir/bin/bat" || return 5
	
	set new_pversion (bat --version | string replace --regex -- '.* ([0-9\.]+).*' '$1') || return 6
	
	echo "Installed version: $new_version"
	
	if ! string match "*$pversion*" -- "$new_pversion"
		echo "Unexpected result, please investigate"
		return 7
	end
	
	echo "Cleaning up ..."
	cd "$initial_dir"
	rm -f "$dldir/bat.tar.gz" || return 8
	rm -rf "$dldir/bat-v""$pversion""-"* || return 9
	
	echo "Complete"
end
