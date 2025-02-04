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
	set -l premount_undo
	
	if test -f "$devdisk"
		# a file was specified: treat as a disk image and mount it with qemu-nbd
		
		# detect nbd module presence (this also serves as a barrier to stop non-linux users)
		modinfo nbd > /dev/null
		or echo "kernel module nbd not available (this function is Linux only)" && return 1
		
		# load nbd module if not loaded
		if ! lsmod | grep -qwE "^nbd"
			echo "nbd module not loaded, loading with 16 nbd devices"
			modprobe nbd max_nbds=16
			or echo "failed to load nbd" && return 1
		end
		
		# find first free nbd device
		set -l freenbd none
		for i in /sys/devices/virtual/block/nbd*
			if ! test -e "$i/pid"
				set freenbd (basename "$i")
				#echo "using /dev/$freenbd"
				break
			end
		end
		if test "$freenbd" = "none"
			echo "no free nbd device found"
			return 1
		end
		if ! type -q qemu-nbd || ! type -q qemu-img
			echo "a file was specified, presumable a disk image, which qmount would mount with qemu-nbd"
			echo "for safety and compatibility, but qemu-nbd or qemu-img is not available - exiting"
			return 1
		end
		
		# detect image format with qemu-img - note: qemu-img sometimes mistakes vpc (.vhd) for raw, so we help
		set -l format
		if string match -qir '.vhd$' -- "$devdisk"
			set format -f vpc
		end
		set qemu_img_info (qemu-img info $format "$devdisk")
		or echo "qemu-img failed to detect disk image format" && return 1
		#printf '%s\n' $qemu_img_info
		string match -qr '^file format: (?<qemu_img_format>.*)' -- $qemu_img_info
		or echo "failed to find image format in output" && return 1
		
		set -l qemu_readonly
		if ! test -w "$devdisk"
			set qemu_readonly "--read-only"
		end
		
		# connect nbd device
		echo "Connecting $qemu_img_format disk image to /dev/$freenbd ..."
		qemu-nbd -f $qemu_img_format $qemu_readonly --connect=/dev/$freenbd "$devdisk"
		or echo "failed to connect qemu-nbd" && return 1
		
		set premount_undo qemu-nbd --disconnect /dev/$freenbd
		
		set devdisk /dev/$freenbd
	else if ! test -b "$devdisk" && ! string match '/*' "$devdisk"
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
		if test "$premount_undo" != ""
			$premount_undo
		end
		return $rs
	end
	
	# examine partitions, mount all through recursion
	set -l has_parts no
	set -l parts
	set -l parts_failed
	for i in "$devdisk"p*
		set has_parts yes
		qmount "$i" && set -a parts "$i"
		or set -a parts_failed "$i"
	end
	if test "$has_parts" = "yes"
		# mounted through recursion
		if test (math (count $parts)" + "(count $parts_failed)) -gt 1
			echo (__spt status_ok)"Partitions mounted:"
			printf "%s " $parts
			if test "$parts_failed" != ""
				echo -n (__spt status_fail)
				echo -n "failed: "
				printf "%s " $parts_failed
			end
			echo
			echo -n (set_color normal)
		end
		return 0
	end
	# TODO: what if the device contains an LVM VG? or partitions?
	
	set -l devshort (string replace --regex -- '^/(dev/)?' '' "$devdisk")
	
	if mountpoint -q "/run/q/$devshort"
		echo "Target directory /run/q/$devshort is already occupied!"
		return 3
	end
	
	mkdir -p "/run/q/$devshort"
	and mount "$devdisk" "/run/q/$devshort"
	
	if ! set -qg __sp_qmount_return_dir || ! string match '/run/q/*' -- "$PWD"
		set -g __sp_qmount_return_dir "$PWD"
	end
	
	cd "/run/q/$devshort"
	and ls -al
end
