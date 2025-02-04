function qumount -d \
	"Umount blockdevices mounted in /run/q/"
	
	set -l devdisk
	
	# recursion for multiple arguments
	if test (count $argv) -gt 1
		for arg in $argv
			qumount "$arg"
		end
		return
	end
	
	if test "$argv[1]" != ""
		set devdisk "$argv[1]"
	else if string match -q "/run/q/*" -- "$PWD"
		set -l original_pwd "$PWD"
		set -l prefix_found "no"
		while string match -q "/run/q/*" -- "$PWD"
			if mountpoint -q .
				set prefix_found "yes"
				set devdisk (string replace --regex -- '^/run/q/' "" "$PWD")
				break
			end
			builtin cd ..
		end
		if test "$prefix_found" = "no"
			builtin cd "$original_pwd"
		end
	end
	
	if test "$devdisk" = ""
		echo "arg 1: device required (/dev may be omitted) when not inside /run/q/"
		return 1
	end
	
	# allow specifying either blockdevice or /run/q/ directory
	set -l devshort (string replace --regex -- '^/(dev/|run/q/)?' '' "$devdisk")
	set -l mpoint "/run/q/$devshort"
	set -l userdir "$PWD"
	if test "$PWD" = "$mpoint" || string match "$mpoint/*" "$PWD"
		# we're blocking umount, cd elsewhere
		cd "/run/q"
	end
	
	if umount "$mpoint"
		rm -d "$mpoint"
	else
		cd "$userdir"
		command fuser -mv "$mpoint"
		return 2
	end
	
	if string match -qr '^(?<nbd>nbd[0-9]+)($|p[0-9]$)' -- "$devshort"
		# find if there are mounted partitions left
		if ! mount | string match -qr '^/dev/'$nbd'[^0-9]'
			echo "Last filesystem of /dev/$nbd closed, disconnecting"
			qemu-nbd --disconnect "/dev/$nbd"
		end
	end
	
	set -l cd_done no
	if test -d "$userdir"
		cd "$userdir"
		set cd_done yes
	end
	if test "$cd_done" != "yes"
		# find next mounted run/q dir in history
		for i in (findmnt --output TARGET --raw | string match '/run/q/*')
			if test -d "$i"
				cd "$i"
				set cd_done yes
				break
			end
		end
	end
	if test "$cd_done" != "yes"
		if set -q __sp_qmount_return_dir && test -d "$__sp_qmount_return_dir"
			cd "$__sp_qmount_return_dir"
			set --erase -g __sp_qmount_return_dir
		end
	end
	
end

