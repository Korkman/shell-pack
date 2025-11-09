function shell-pack-deps -d \
	"Perform various actions to manage dependencies"
	if test "$argv[1]" = "check"
		shell-pack-check-deps
	else if test "$argv[1]" = "install"
		if test "$argv[2]" = "fzf"
			shell-pack-deps-install-fzf $argv[3] || echo "Failed with status $status"
		else if test "$argv[2]" = "ripgrep"
			shell-pack-deps-install-ripgrep $argv[3] || echo "Failed with status $status"
		else if test "$argv[2]" = "dool"
			shell-pack-deps-install-dool $argv[3] || echo "Failed with status $status"
		else
			echo "Invalid argument"
			return 2
		end
	else
		echo "Invalid argument"
		return 1
	end
end

function shell-pack-deps-install-fzf
	echo "Project website: https://github.com/junegunn/fzf"
	set pversion "$argv[1]"
	if test "$pversion" = ""
		set pversion "0.66.1"
	end
	set tpl_arm_v6 "https://github.com/junegunn/fzf/releases/download/vVERSION/fzf-VERSION-linux_armv6.tar.gz"
	set tpl_arm_v7 "https://github.com/junegunn/fzf/releases/download/vVERSION/fzf-VERSION-linux_armv7.tar.gz"
	set tpl_x86_64_apple_darwin "https://github.com/junegunn/fzf/releases/download/vVERSION/fzf-VERSION-darwin_amd64.tar.gz"
	set tpl_x86_64_linux "https://github.com/junegunn/fzf/releases/download/vVERSION/fzf-VERSION-linux_amd64.tar.gz"
	
	set initial_dir "$PWD"
	
	if test (uname -m) = "x86_64"
		if test (uname -s) = "Darwin"
			set url "$tpl_x86_64_apple_darwin"
		else
			set url "$tpl_x86_64_linux"
		end
	else if test (uname -m) = "armv7l"
		set url "$tpl_arm_v7"
	else if test (uname -m) = "armv6l"
		set url "$tpl_arm_v6"
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
	
	rm -f fzf.tar.gz
	
	echo "Downloading $url ..."
	dl -q "$url" > fzf.tar.gz || return 3
	
	cfd fzf.tar.gz || return 4
	
	echo "Installing to ""$__sp_dir""/bin/fzf ..."
	rm -f "$__sp_dir/bin/fzf"
	cp "fzf" "$__sp_dir/bin/fzf" || return 5
	
	set new_pversion (fzf --version | string replace --regex -- '([0-9\.]+).+' '$1') || return 6
	
	echo "Installed version: $new_version"
	
	if ! string match "$pversion" -- "$new_pversion"
		echo "Unexpected result, please investigate"
		return 7
	end
	
	echo "Cleaning up ..."
	cd "$initial_dir"
	rm -f "$dldir/fzf.tar.gz" || return 8
	rm -f "$dldir/fzf" || return 9
	
	echo "Complete"
end

function shell-pack-deps-install-ripgrep
	echo "Project website: https://github.com/BurntSushi/ripgrep"
	set pversion "$argv[1]"
	if test "$pversion" = ""
		set pversion "15.1.0"
	end
	set tpl_arm_other "https://github.com/BurntSushi/ripgrep/releases/download/VERSION/ripgrep-VERSION-armv7-unknown-linux-gnueabihf.tar.gz"
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
	
	cfd ripgrep.tar.gz || return 4
	
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

function shell-pack-deps-install-dool
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
	
	cfd dool.tar.gz || return 4
	
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
