function qchroot -d "Quickly enter a chroot, ensuring proper mounts are available"
	argparse --stop-nonopt -n qchroot 'k/keep' 'm/mount-only' 'h/help' 'u/user=' 's/shell=' 'c/cmd=' -- $argv
	and not set -q _flag_help
	or begin
		echo "\
Usage: qchroot [ OPTIONS ... ] [ DIRECTORY [ COMMAND [ ARGS ... ] ] ]

Quickly enter a chroot, ensuring proper mounts are available.

Do not speficy DIRECTORY to use current directory.

   -k/--keep          Do not run qunchroot after leaving chroot
   -m/--mount-only    Do not run chroot after preparing mounts
   -s/--shell CMD        Use CMD for shell inside chroot
   -c/--cmd CMD          Run CMD in shell inside chroot
   -u/--user USER        What user to change into inside chroot
   --help             Show this help
"
		if set -q _flag_help
			return 0
		else
			return 2
		end
	end
	
	set -l targetDir "$PWD"
	set -l su_args
	if [ (count $argv) -gt 0 ]
		set targetDir "$argv[1]"
	end
	
	if set -q _flag_shell
		set su_args $su_args "-s" "$_flag_shell"
	end
	
	if [ (count $argv) -gt 1 ]
		set su_args "-c" "$argv[2..-1]"
		if set -q _flag_cmd
			echo "Cannot use positional argument 2 for COMMAND and have --cmd at the same time"
			return 1
		end
	else if set -q _flag_cmd
		set su_args $su_args "-c" "$_flag_cmd"
	else
		set su_args $su_args "--login"
	end
	
	if set -q _flag_user
		set su_args $su_args "$_flag_user"
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
		# start with a clean env
		# inside chroot, run env to copy over a few select variables
		# pass them as whitelist to "su", which creates a login shell by default
		env -i (command -v chroot) "$targetDir" \
			env "debian_chroot=$debian_chroot" "LC_NERDLEVEL=$LC_NERDLEVEL" "TERM=$TERM" \
			su -s /bin/sh --whitelist-environment LC_NERDLEVEL,debian_chroot \
			$su_args \
		;
		if ! set -q _flag_keep
			qunchroot "$targetDir"
		end
	end
end
