function __sp_cap_tar_has_one_fs
	if tar --help &| string match -q -- '*--one-file-system*'
		set -g __cap_tar_has_one_fs true
		return 0
	else
		set -g __cap_tar_has_one_fs false
		return 1
	end
end
