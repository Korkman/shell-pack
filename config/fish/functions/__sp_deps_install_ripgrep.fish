function __sp_deps_install_ripgrep
	echo "Project website: https://github.com/BurntSushi/ripgrep"
	set pversion "$argv[1]"
	if test "$pversion" = ""
		set pversion "15.1.0"
	end
	set tpl_arm_other "https://github.com/BurntSushi/ripgrep/releases/download/VERSION/ripgrep-VERSION-armv7-unknown-linux-gnueabihf.tar.gz"
	set tpl_arm_aarch64 "https://github.com/BurntSushi/ripgrep/releases/download/VERSION/ripgrep-VERSION-aarch64-unknown-linux-gnu.tar.gz"
	set tpl_x86_64_apple_darwin "https://github.com/BurntSushi/ripgrep/releases/download/VERSION/ripgrep-VERSION-x86_64-apple-darwin.tar.gz"
	set tpl_x86_64_linux "https://github.com/BurntSushi/ripgrep/releases/download/VERSION/ripgrep-VERSION-x86_64-unknown-linux-musl.tar.gz"
	
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
	
	rm -f ripgrep.tar.gz
	
	echo "Downloading $url ..."
	dl -q "$url" > ripgrep.tar.gz || return 3
	
	cfd ripgrep.tar.gz . || return 4
	
	echo "Installing to ""$__sp_dir""/bin/rg ..."
	cd "ripgrep-""$pversion""-"* || return 5
	rm -f "$__sp_dir/bin/rg"
	cp "rg" "$__sp_dir/bin/rg" || return 5
	
	set new_pversion (rg --version) || return 6
	
	echo "Installed version: $new_version"
	
	if ! string match "*$pversion*" -- "$new_pversion"
		echo "Unexpected result, please investigate"
		return 7
	end
	
	echo "Cleaning up ..."
	cd "$initial_dir"
	rm -f "$dldir/ripgrep.tar.gz" || return 8
	rm -rf "$dldir/ripgrep-""$pversion""-"* || return 9
	
	echo "Complete"
end
