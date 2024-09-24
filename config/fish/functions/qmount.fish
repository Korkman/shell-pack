function qmount -d \
	"Mount and browse devices with autocomplete"
	# - creates directories derived from the device path in /run/q/
	# - mounts with default options
	# - cd && ls
	
	
	if test "$argv[1]" = ""
		echo "qmount will create /run/q/[device name], mount and cd there"
		echo "arg #1: device name (without /dev) required"
		return 1
	end
	
	if test "$argv[2]" != ""
		echo "no more than 1 argument allowed"
		return 1
	end

	set -l devdisk "$argv[1]"
	if ! test -b "$devdisk" && ! string match '/*' "$devdisk"
		# not an absolute path, does not exist: fix up path
		if test -b "/dev/$devdisk"
			# try prepend /dev/
			set devdisk "/dev/$devdisk"
		end
	end

	blkid "$devdisk"
	set -l rs $status
	if not test $rs -eq 0
		echo "$devdisk is not recognized by blkid"
		return $rs
	end
	
	set -l devshort (string replace --regex -- '^/(dev/)?' '' "$devdisk")
	
	if mountpoint -q "/run/q/$devshort"
		echo "Target directory /run/q/$devshort is already occupied!"
		return 3
	end
	
	mkdir -p "/run/q/$devshort"
	and mount "$devdisk" "/run/q/$devshort"
	and set -g __sp_qmount_return_dir "$PWD"
	and cd "/run/q/$devshort"
	and ls -al
end
