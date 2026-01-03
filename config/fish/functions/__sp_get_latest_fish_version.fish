function __sp_get_latest_fish_version
	set -l repo_version
	__sp_http --timeout=1 "https://api.github.com/repos/fish-shell/fish-shell/releases/latest" | string match -gq --regex '"tag_name": "(?<repo_version>[^"]+)"'
	or return 2
	echo "$repo_version"
end
