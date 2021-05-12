function shell-pack-check-upgrade -d \
	"Check for an upgrade to shell-pack"
	set result (curl -sL "https://raw.githubusercontent.com/Korkman/shell-pack/latest/config/fish/functions/shell-pack-version.fish" | string match --regex 'echo.*([0-9](\.[0-9])+)')
	#set result (curl -sL "https://nxdomain.local" | string match --regex 'echo.*([0-9](\.[0-9])+)')
	if test $status -eq 0
		set current_version (shell-pack-version)
		if test "$current_version" != "$result[2]"
			echo "New version: run 'upgrade-shell-pack' to upgrade to $result[2]!"
		end
	else
		echo "NOTE: Unable to contact server for upgrade notification"
	end
end
