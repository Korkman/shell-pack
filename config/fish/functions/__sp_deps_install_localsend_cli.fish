function __sp_deps_install_localsend_cli -d "Install localsend-cli"
	echo "Project website: https://github.com/localsend/localsend"
	
	set -l tpl_arm_aarch64_apple_darwin "https://github.com/localsend/localsend/releases/download/TAG/LocalSend-CLI-VERSION-macos-arm-64.tar.gz"
	set -l tpl_x86_64_apple_darwin "https://github.com/localsend/localsend/releases/download/TAG/LocalSend-CLI-VERSION-macos-x86-64.tar.gz"
	set -l tpl_arm_aarch64_linux "https://github.com/localsend/localsend/releases/download/TAG/LocalSend-CLI-VERSION-linux-arm-64.tar.gz"
	set -l tpl_x86_64_linux "https://github.com/localsend/localsend/releases/download/TAG/LocalSend-CLI-VERSION-linux-x86-64.tar.gz"
	
	set -l initial_dir "$PWD"
	
	set -l uname_s (uname -s)
	set -l uname_m (uname -m)
	set -l url
	
	if test "$uname_m" = "x86_64"; or test "$uname_m" = "amd64"
		if test "$uname_s" = "Darwin"
			set url "$tpl_x86_64_apple_darwin"
		else if test "$uname_s" = "Linux"
			set url "$tpl_x86_64_linux"
		else
			echo "Unsupported OS: $uname_s"
			return 1
		end
	else if test "$uname_m" = "aarch64"; or test "$uname_m" = "arm64"
		if test "$uname_s" = "Darwin"
			set url "$tpl_arm_aarch64_apple_darwin"
		else if test "$uname_s" = "Linux"
			set url "$tpl_arm_aarch64_linux"
		else
			echo "Unsupported OS: $uname_s"
			return 1
		end
	else
		echo "No matching architecture found, please try downloading yourself"
		return 1
	end
	
	set -l pversion "$argv[1]"
	set -l tag
	if test -z "$pversion"; or test "$pversion" = "latest"
		echo "Looking up latest release tag ..."
		set tag (dl -q "https://api.github.com/repos/localsend/localsend/releases/latest" | string match --regex '"tag_name":\s*"[^"]+"' | string match --regex 'v[0-9][^"]*')
		if test -z "$tag"
			echo "Could not determine latest release tag"
			return 1
		end
		set pversion (string replace --regex '^v' '' -- "$tag")
	else
		set pversion (string replace --regex '^v' '' -- "$pversion")
		set tag "v$pversion"
	end
	
	read -P "OK to download and execute release file for $tag? (Y/n)" answer; or set answer n
	if test -n "$answer"; and test "$answer" != "y"; and test "$answer" != "Y"
		return 1
	end
	
	set -l dldir ~/.cache/shell-pack-downloads
	mkdir -p "$dldir"; or return 2
	cd "$dldir"; or return 2
	set url (string replace --all 'TAG' "$tag" -- "$url")
	set url (string replace --all 'VERSION' "$pversion" -- "$url")
	set -l archive (string replace --regex -- '^.*/' '' "$url")
	
	rm -f "$archive"
	
	echo "Downloading $url ..."
	dl -q "$url" > "$archive"; or return 3
	
	cfd "$archive" .; or return 4
	
	echo "Installing to ""$__sp_dir""/bin/localsend-cli ..."
	rm -f "$__sp_dir/bin/localsend-cli"
	cp "localsend-cli" "$__sp_dir/bin/localsend-cli"; or return 5
	chmod +x "$__sp_dir/bin/localsend-cli"
	
	set -l new_pversion ("$__sp_dir/bin/localsend-cli" --version | string replace --regex -- '.* ([0-9\.]+).*' '$1'); or return 6
	
	echo "Installed version: $new_pversion"
	
	if not string match "*$pversion*" -- "$new_pversion"
		echo "Unexpected result, please investigate"
		return 7
	end
	
	echo "Cleaning up ..."
	cd "$initial_dir"
	rm -f "$dldir/$archive"
	rm -f "$dldir/localsend-cli"
	rm -f "$dldir/._localsend-cli"
	
	echo "Complete"
end
