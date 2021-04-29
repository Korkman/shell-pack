function upgrade-shell-pack -d \
	"Download & install latest shell-pack"
	
	if [ "$UPGRADE_SHELLPACK" != "no" ]
		curl -s -L "https://github.com/Korkman/shell-pack/raw/latest/get.sh" | sh || return 1
		shell-pack-deps check
		reload
	else
		echo "upgrade-shell-pack disabled"
		return 2
	end
end
