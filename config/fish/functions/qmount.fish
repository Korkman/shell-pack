function qmount -d \
	"Mount and browse devices and disk image files with autocomplete"
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
		echo "Attemting to mount disk image"
		
		# detect nbd module presence (this also serves as a barrier to stop non-linux users)
		modinfo nbd > /dev/null
		or echo "kernel module nbd not available (this function is Linux only)" && return 1
		
		# load nbd module if not loaded
		if ! lsmod | grep -qwE "^nbd"
			if ! set -q NBDS_MAX
				set NBDS_MAX 8
			end
			echo "nbd module not loaded, loading with $NBDS_MAX nbd devices"
			modprobe nbd nbds_max=$NBDS_MAX
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
		or qemu-nbd -f $qemu_img_format --read-only --connect=/dev/$freenbd "$devdisk"
		or echo "failed to connect qemu-nbd" && return 1
		
		# Recurse into created block device
		qmount /dev/$freenbd
		or begin
			read -P "Undo $freenbd setup? (Y/n)" answer || set answer "n"
			if string match -qri '^(y|)$' -- "$answer"
				qemu-nbd --disconnect /dev/$freenbd
			end
		end
		return
	else if ! test -b "$devdisk" && ! string match '/*' "$devdisk"
		# not an absolute path, does not exist: fix up path
		if test -b "/dev/$devdisk"
			# try prepend /dev/
			set devdisk "/dev/$devdisk"
		end
	end
	
	# gain intel about block device with blkid
	if ! test -b "$devdisk"
		echo "Not a blockdevice: $devdisk"
		return 1
	end
	set -l blkid_rs (blkid "$devdisk")
	echo "$blkid_rs"
	set -l rs $status
	if not test $rs -eq 0
		echo "$devdisk is not recognized by blkid"
		return $rs
	end
	
	# Unlock, recurse dm-crypt volume
	if string match -q '*TYPE="crypto_LUKS"*' -- "$blkid_rs"
		set -l cryptname "qmountLuks"(basename $devdisk)
		set -l cryptdev "/dev/mapper/$cryptname"
		if test -e "$cryptdev"
			echo "$cryptdev already exists, sorry"
			return 1
		end
		cryptsetup luksOpen "$devdisk" "$cryptname"
		or echo "cryptsetup failed" && return 1
		qmount "$cryptdev"
		or begin
			set -l rs $status
			read -P "Undo $cryptname setup? (Y/n)" answer || set answer "n"
			if string match -qri '^(y|)$' -- "$answer"
				cryptsetup luksClose "$cryptname"
			end
		end
		return
	end
	
	# setup partition stats
	set -l has_parts no
	set -l parts
	set -l parts_failed
	
	# Recurse LVM2 partitions
	if string match -q '*TYPE="LVM2_member"*' -- "$blkid_rs"
		set pvinfo (pvdisplay --colon "$devdisk" | string split ':')
		or echo "pvdisplay failed for $devdisk" && return 1
		set vgname "$pvinfo[2]"
		vgchange -ay "$vgname"
		or echo "vgchange -ay $vgname failed" && return 1
		set lvlist (lvs --noheadings -o lv_name "$vgname" | string trim)
		for i in $lvlist
			set has_parts yes
			set i "/dev/$vgname/$i"
			qmount "$i" && set -a parts "$i"
			or set -a parts_failed "$i"
		end
		echo "NOTE: while qmount can recurse LVM, qumount can't yet."
		echo "You will have to vgchange -an $vgname and dismantle the chain from there"
	end
	
	# Recurse MBR/GPT partitions
	if ! test -e $devdisk"p1"
		kpartx -a "$devdisk"
	end
	for i in "$devdisk"p*
		set has_parts yes
		qmount "$i" && set -a parts "$i"
		or set -a parts_failed "$i"
	end
	
	# Inform about recursion, exit
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
		test "$parts" != "" && return 0
		return 1
	end
	
	# create shorthand, prepare directory for mount
	set -l devshort (string replace --regex -- '^/(dev/)?' '' "$devdisk")
	set -l mpoint "/run/q/$devshort"
	if mountpoint -q "$mpoint"
		echo "Target directory $mpoint is already occupied!"
		return 3
	end
	mkdir -p "$mpoint"
	
	# perform mount
	and mount "$devdisk" "$mpoint"
	or return $status
	
	# save initial directory outside of /run/q to return to later
	if ! set -qg __sp_qmount_return_dir || ! string match -q '/run/q/*' -- "$PWD"
		set -g __sp_qmount_return_dir "$PWD"
	end
	
	# cd into mount
	echo (__spt status_ok)"$mpoint mounted"(set_color normal)
	cd "$mpoint"
	and ls -al
	
	# add '/run/q' to CDPATH for extra easy navigation ("cd sda2")
	if test "$CDPATH" = ""
		set -g CDPATH "."
	end
	if ! contains '/run/q/' $CDPATH
		set -ga CDPATH '/run/q/'
	end
end
