function shell-pack-upgrade -d \
	"Download & install latest shell-pack or upgrade fish"
	
	set -l verb "$argv[1]"
	
	if test "$verb" = "fish"
		__sp_upgrade_fish $argv[2]
		return
	end
	
	if test "$verb" = "check"
		if test "$argv[2]" = "fish"
			__sp_upgrade_fish check
		else
			__sp_upgrade_check
		end
		return
	end
	
	if test "$verb" = ""
		set tag 'latest'
	else
		set tag $verb
	end
	
	if test "$UPGRADE_SHELLPACK" != "no"
		__sp_http "https://raw.githubusercontent.com/Korkman/shell-pack/$tag/get.sh" | sh -s "$tag" || return 1
		shell-pack-deps check
		shell-pack-prefs install
		reload
	else
		echo "shell-pack-upgrade disabled"
		return 2
	end
end
