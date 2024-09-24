function qumount -d \
	"Umount blockdevices mounted in /run/q/"
	
	set -l devdisk

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
	
	if test "$argv[2]" != ""
		echo "no more than 1 argument allowed"
		return 1
	end
	
	# allow specifying either blockdevice or /run/q/ directory
	set -l devshort (string replace --regex -- '^/(dev/|run/q/)?' '' "$devdisk")
	set -l mpoint "/run/q/$devshort"
	if test "$PWD" = "$mpoint" || string match "$mpoint/*" "$PWD"
		# we're blocking umount, cd elsewhere
		if set -q __sp_qmount_return_dir && test -d "$__sp_qmount_return_dir"
			cd "$__sp_qmount_return_dir"
		else
			cd "/run/q"
		end
	end
	
	if umount "$mpoint"
		rm -d "$mpoint"
	else
		command fuser -mv "$mpoint"
		return 2
	end
	
	if set -q __sp_qmount_return_dir
		set --erase -g __sp_qmount_return_dir
	end
end

