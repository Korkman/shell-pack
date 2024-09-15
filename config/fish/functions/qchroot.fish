function qchroot -d "Quickly enter a chroot, ensuring proper mounts are available"
	argparse -n qchroot 'k/keep' 'm/mount-only' 'h/help' -- $argv
	and not set -q _flag_help
	or begin
		echo "\
Usage: qchroot [ TARGET ] [ --keep | --mount-only | --help ]

Quickly enter a chroot, ensuring proper mounts are available.

Do not speficy TARGET to use current directory.

   -k/--keep          Do not run qunchroot after leaving chroot.
   -m/--mount-only    Do not run chroot after preparing mounts.
   --help             Show this help
"
		if set -q _flag_help
			return 0
		else
			return 2
		end
	end
	if [ (count $argv) -gt 0 ]
		set targetDir $argv[1]
	else
		set targetDir $PWD
	end
	set targetDir (realpath "$targetDir")
	if ! [ -d "$targetDir" ]
		echo "Not a valid directory"
		return 1
	end
	# test if proc, sys, dev exist
	if ! [ -d "$targetDir/proc" ]
		echo "$targetDir/proc missing"
		return 1
	end
	if ! [ -d "$targetDir/sys" ]
		echo "$targetDir/sys missing"
		return 1
	end
	if ! [ -d "$targetDir/dev" ]
		echo "$targetDir/dev missing"
		return 1
	end
	
	
	echo "Adding bind mounts ..."
	# mount only if not already mounted
	if ! findmnt "$targetDir/sys" > /dev/null
		# mount bind recursive to grab /dev/pty, cgroup stuff on modern systems
		mount --rbind /sys "$targetDir/sys"    || exit 1
		# inform kernel this is a slave hierarchy, so umount does not affect original
		mount --make-rslave "$targetDir/sys"
	end
	# repeat
	if ! findmnt "$targetDir/dev" > /dev/null
		mount --rbind /dev "$targetDir/dev"    || exit 2
		mount --make-rslave "$targetDir/dev"
	end
	if ! findmnt "$targetDir/proc" > /dev/null
		mount --rbind /proc "$targetDir/proc"  || exit 3
		mount --make-rslave "$targetDir/proc"
	end
	if ! findmnt "$targetDir/run" > /dev/null
		mount -t tmpfs tmpfs "$targetDir/run"
	end
	if ! set -q _flag_mount_only
		echo "Chroot ..."
		set -l debian_chroot (string split -r -m1 / -- $targetDir)[2]
		env -i /usr/sbin/chroot "$targetDir" env login -f root debian_chroot=$debian_chroot LC_NERDLEVEL=$LC_NERDLEVEL TERM=$TERM
		if ! set -q _flag_keep
			qunchroot "$targetDir"
		end
	end
end
