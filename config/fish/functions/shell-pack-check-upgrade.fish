function shell-pack-check-upgrade -d \
	"Check for an upgrade to shell-pack"
	# download latest shell-pack-version.fish and grep the version from there
	set result (curl --max-time 1 -sL "https://raw.githubusercontent.com/Korkman/shell-pack/latest/config/fish/functions/shell-pack-version.fish" | string match --regex 'echo.*([0-9]+(\.[0-9]+)+)')
	if test $status -eq 0
		set installed_version (shell-pack-version)
		set latest_version "$result[2]"
		if test "$installed_version" != "$latest_version"
			echo "Update: run 'upgrade-shell-pack' to upgrade from "$installed_version" to "$latest_version"!"
		end
	else
		echo "NOTE: Unable to check for latest shell-pack version (offline?)"
	end
end
