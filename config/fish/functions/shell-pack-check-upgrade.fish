function shell-pack-check-upgrade -d \
	"Check for an upgrade to shell-pack"
	# call github API to get latest release tag
	__sp_http --timeout=2 "https://api.github.com/repos/Korkman/shell-pack/releases/latest" | string match -gq --regex '"tag_name": "v(?<latest_version>[^"]+)"'
	or begin
		echo "NOTE: Unable to check for latest shell-pack version (offline?)"
		return
	end
	set installed_version (shell-pack-version)
	if test "$installed_version" != "$latest_version"
		echo "Update: run 'upgrade-shell-pack' to upgrade from "$installed_version" to "$latest_version"!"
	end
	
	# also check for FISH upgrade
	upgrade-fish --subtle
end
