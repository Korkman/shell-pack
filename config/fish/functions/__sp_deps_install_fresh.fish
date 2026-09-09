function __sp_deps_install_fresh
	echo "Project website: https://github.com/sinelaw/fresh"
	
	set tpl_aarch64_apple_darwin "https://github.com/sinelaw/fresh/releases/download/TAG/fresh-editor-aarch64-apple-darwin.tar.xz"
	set tpl_x86_64_apple_darwin "https://github.com/sinelaw/fresh/releases/download/TAG/fresh-editor-x86_64-apple-darwin.tar.xz"
	set tpl_aarch64_linux "https://github.com/sinelaw/fresh/releases/download/TAG/fresh-editor-aarch64-unknown-linux-musl.tar.xz"
	set tpl_x86_64_linux "https://github.com/sinelaw/fresh/releases/download/TAG/fresh-editor-x86_64-unknown-linux-musl.tar.xz"
	set tpl_aarch64_freebsd "https://github.com/sinelaw/fresh/releases/download/TAG/fresh-editor-aarch64-unknown-freebsd.tar.xz"
	set tpl_x86_64_freebsd "https://github.com/sinelaw/fresh/releases/download/TAG/fresh-editor-x86_64-unknown-freebsd.tar.xz"
	
	set initial_dir "$PWD"
	
	set uname_s (uname -s)
	
	if test (uname -m) = "x86_64" || test (uname -m) = "amd64"
		if test "$uname_s" = "Darwin"
			set url "$tpl_x86_64_apple_darwin"
		else if test "$uname_s" = "Linux"
			set url "$tpl_x86_64_linux"
		else if test "$uname_s" = "FreeBSD"
			set url "$tpl_x86_64_freebsd"
		else
			echo "Unsupported OS: $uname_s"
			return 1
		end
	else if test (uname -m) = "aarch64" || test (uname -m) = "arm64"
		if test "$uname_s" = "Darwin"
			set url "$tpl_aarch64_apple_darwin"
		else if test "$uname_s" = "Linux"
			set url "$tpl_aarch64_linux"
		else if test "$uname_s" = "FreeBSD"
			set url "$tpl_aarch64_freebsd"
		else
			echo "Unsupported OS: $uname_s"
			return 1
		end
	else
		echo "No matching architecture found, please try downloading yourself"
		return 1
	end
	
	if test $argv[1] = "latest"
		echo "Looking up latest release tag ..."
		set tag (dl -q "https://api.github.com/repos/sinelaw/fresh/releases/latest" | string match --regex '"tag_name":\s*"[^"]+"' | string match --regex 'v[0-9][^"]*') || return 1
		if test "$tag" = ""
			echo "Could not determine latest release tag"
			return 1
		end
	else
		set tag $argv[1]
	end
	
	set dldir ~/.cache/shell-pack-downloads
	mkdir -p "$dldir" || return 2
	cd "$dldir" || return 2
	set url (string replace --all 'TAG' "$tag" -- "$url")
	set archive (string replace --regex -- '^.*/' '' "$url")
	
	rm -f "$archive"
	
	echo "Downloading $url ..."
	dl -q "$url" > "$archive" || return 3
	
	cfd "$archive" . || return 4
	
	echo "Installing to ""$__sp_dir""/bin/fresh ..."
	cd "fresh-editor-"*/ || return 5
	rm -f "$__sp_dir/bin/fresh"
	cp "fresh" "$__sp_dir/bin/fresh" || return 5
	
	set new_pversion (fresh --version) || return 6
	
	echo "Installed version: $new_pversion"
	
	echo "Cleaning up ..."
	cd "$initial_dir"
	rm -f "$dldir/$archive" || return 8
	rm -rf "$dldir/fresh-editor-"*/ || return 9
	
	echo "Complete"
end
