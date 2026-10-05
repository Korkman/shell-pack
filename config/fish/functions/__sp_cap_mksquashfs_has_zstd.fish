function __sp_cap_mksquashfs_has_zstd
	if command mksquashfs -help-comp all 2>&1 | string match -q -- '*zstd*'
		set -g __cap_mksquashfs_has_zstd true
		return 0
	else
		set -g __cap_mksquashfs_has_zstd false
		return 1
	end
end
