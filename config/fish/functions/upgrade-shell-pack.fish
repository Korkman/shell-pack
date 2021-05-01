function upgrade-shell-pack -d \
	"Download & install latest shell-pack"
	
	set tag 'latest'
	if ! set -q $argv[1]
		set tag $argv[1]
	end
	
	if [ "$UPGRADE_SHELLPACK" != "no" ]
		curl -s -L "https://github.com/Korkman/shell-pack/raw/$tag/get.sh" | sh -s || return 1
		shell-pack-deps check
		reload
	else
		echo "upgrade-shell-pack disabled"
		return 2
	end
end
