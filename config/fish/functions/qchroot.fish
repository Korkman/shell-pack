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
	set -l chroot_shell /bin/sh
	set -l chroot_cmd
	if [ (count $argv) -gt 0 ]
		set targetDir "$argv[1]"
	end
	
	if set -q _flag_shell
		set chroot_shell "$_flag_shell"
	end
	
	if [ (count $argv) -gt 1 ]
		if set -q _flag_cmd
			echo "Cannot use positional argument 2 for COMMAND and have --cmd at the same time"
			return 1
		end
		set chroot_cmd (string join " " -- $argv[2..-1])
	else if set -q _flag_cmd
		set chroot_cmd "$_flag_cmd"
	end
	
	set targetDir (path resolve -- "$targetDir")
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
		set -l chroot_vars "debian_chroot=$debian_chroot" "LC_NERDLEVEL=$LC_NERDLEVEL" "TERM=$TERM" "LANG=$LANG" "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
		if test -z "$chroot_cmd"; and not set -q _flag_user
			# root login shell: run it directly, so /etc/profile and ~/.profile load and the TTY is kept
			env -i (command -v chroot) "$targetDir" \
				env $chroot_vars "HOME=/root" "USER=root" "SHELL=$chroot_shell" \
				"$chroot_shell" -l \
			;
		else
			# su keeps the environment without --login and creates no session, so COMMAND runs
			# keep their variables. Interactive -u shells use --login, which clears them except TERM
			set -l su_args -s "$chroot_shell"
			if test -n "$chroot_cmd"
				set su_args $su_args -c "$chroot_cmd"
			else
				set su_args $su_args --login
			end
			if set -q _flag_user
				set su_args $su_args "$_flag_user"
			end
			env -i (command -v chroot) "$targetDir" \
				env $chroot_vars \
				su $su_args \
			;
		end
		if ! set -q _flag_keep
			qunchroot "$targetDir"
		end
	end
end
