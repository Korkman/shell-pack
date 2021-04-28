function upgrade-shell-pack -d \
	"Download & install latest shell-pack"
	
	(curl -s -L "https://github.com/Korkman/shell-pack/raw/latest/get.sh" | sh) || return
	
	reload
end
