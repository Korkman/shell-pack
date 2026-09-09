function __sp_deps_install_fzf
	echo "Project website: https://github.com/junegunn/fzf"
	set pversion "$argv[1]"
	if test "$pversion" = ""
		set pversion "0.70.0"
	end
	set tpl_arm_v6 "https://github.com/junegunn/fzf/releases/download/vVERSION/fzf-VERSION-linux_armv6.tar.gz"
	set tpl_arm_v7 "https://github.com/junegunn/fzf/releases/download/vVERSION/fzf-VERSION-linux_armv7.tar.gz"
	set tpl_arm_aarch64 "https://github.com/junegunn/fzf/releases/download/vVERSION/fzf-VERSION-linux_arm64.tar.gz"
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
	else if test (uname -m) = "aarch64"
		set url "$tpl_arm_aarch64"
	else
		echo "No matching architecture found, please try downloading yourself"
		return 1
	end
	
	set dldir ~/.cache/shell-pack-downloads
	mkdir -p "$dldir" || return 2
	cd "$dldir" || return 2
	set url (string replace --all 'VERSION' "$pversion" -- "$url")
	
	rm -f fzf.tar.gz
	
	echo "Downloading $url ..."
	dl -q "$url" > fzf.tar.gz || return 3
	
	cfd fzf.tar.gz . || return 4
	
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
