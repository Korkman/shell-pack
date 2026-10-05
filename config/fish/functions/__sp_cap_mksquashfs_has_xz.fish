function __sp_cap_mksquashfs_has_xz
	if command mksquashfs -help-comp all 2>&1 | string match -q -- '*xz*'
		set -g __cap_mksquashfs_has_xz true
		return 0
	else
		set -g __cap_mksquashfs_has_xz false
		return 1
	end
end
