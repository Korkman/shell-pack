set __sp_fish_repo "https://github.com/fish-shell/fish-shell"

function upgrade-fish
	argparse s/subtle -- $argv
	or return
	set -l repo_version (__sp_get_newer_fish_version)
	switch $status
		case 0
			if set -q _flag_subtle
				echo "Update: run 'upgrade-fish' to upgrade from "$FISH_VERSION" to "$repo_version"!"
				return
			end
			echo "A new version of FISH is available: $repo_version"
			set -l install_arch
			if ! string match -qr '^Linux (?<install_arch>x86_64|aarch64)$' -- (uname -sm)
				# static builds currently only exist for Linux x86_64 and aarch64
				return 0
			end
			echo "Do you want to upgrade FISH to a static build of version $repo_version now? (Y/n)"
			read -P "" -l answer || set -l answer n
			if ! string match -qr '^(y|Y|)$' -- "$answer"
				echo "Aborted."
				return 1
			end
			set -l sudo
			set -l sudo_hint
			if test -w "/usr/local/bin"
				set sudo "env"
				set sudo_hint ""
			else
				set sudo "sudo"
				set sudo_hint " (requires sudo)"
			end
			set -l install_dir
			echo "Install to /usr/local/bin for all users"$sudo_hint"? (Y/n)"
			read -P "" -l answer || set -l answer n
			if string match -qr '^(y|Y|)$' -- "$answer"
				set install_dir "/usr/local/bin"
			else
				set sudo "env"
				set install_dir "$HOME/.local/bin"
			end
			if test -e "$install_dir/fish" && test "$install_dir/fish" != (status fish-path)
				echo "FISH is already installed to $install_dir/fish, but your current shell is from "(status fish-path)"."
				echo "Please adjust your PATH to use the fish from $install_dir."
				return 1
			end
			
			if ! contains "$install_dir" $PATH
				echo "$install_dir is not in your PATH. You need to add it first."
				return 1
			end
			
			set -l dl_dir "$HOME/.cache/shell-pack-downloads/upgrade-fish-tmp"
			rm -rf "$dl_dir"
			mkdir -p "$dl_dir"
			set -l dl_path "$dl_dir/fish-$repo_version-linux-$install_arch.tar.xz"
			echo "Downloading fish $repo_version for $install_arch ..."
			dl "$__sp_fish_repo/releases/download/$repo_version/fish-$repo_version-linux-$install_arch.tar.xz" "$dl_path" 2> /dev/null
			or begin echo "Error: download failed"; return 2; end
			cfd "$dl_path" "$dl_dir"
			or begin echo "Error: decompression with cfd failed"; return 3; end
			# a fish was summoned
			$sudo cp "$dl_dir/fish" "$install_dir/fish.new"
			or begin echo "Error: copy failed"; return 4; end
			$sudo chmod +x "$install_dir/fish.new"
			or begin echo "Error: chmod failed"; return 9; end
			$sudo mv -f "$install_dir/fish.new" "$install_dir/fish"
			or begin echo "Error: move failed"; return 10; end
			
			rm -rf "$dl_dir"
			
			if test (command -v fish) != "$install_dir/fish"
				echo "Error: installed FISH to $install_dir/fish, but "(command -v fish)" has precedence in PATH."
				return 8
			end
			
			if test "$TMUX" != "" && test "$install_dir/fish" != "$SHELL"
				echo "NOTE: Your SHELL variable is $SHELL, but the new fish is installed to $install_dir/fish."
				echo "You might want to restart tmux for the new location to take effect on new panes."
			end
			
			echo "FISH was upgraded to $repo_version. Reloading ..."
			reload
			or begin echo "Error: reload failed"; return 7; end
		case 1
			set -q _flag_subtle || echo "You are already using the latest fish version: $repo_version"
			return 0
		case 2
			set -q _flag_subtle || echo "Error"
			return 1
	end
end

function __sp_get_newer_fish_version
	set -l repo_version
	
	__sp_http_head --timeout=1 "$__sp_fish_repo/releases/latest" | string match -gq --regex '^location: .*/releases/tag/(?<repo_version>[0-9]+\.[0-9]+\.[0-9]+).*'
	or return 2
	# compare versions and upgrade if needed
	if test (__sp_vercmp "$FISH_VERSION" "$repo_version") -ge 0
		echo "$repo_version"
		return 1
	end

	echo "$repo_version"
	return 0
end
