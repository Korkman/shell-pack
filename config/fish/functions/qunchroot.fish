function qunchroot -d "Tear down bind mounts in chroot"
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
	# sanity check
	if [ "$targetDir" = "/" ]
		echo "Executing this on the root dir would be suicidal"
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
	
	echo -n "Removing bind mounts .."
	set -l failed
	for i in 1 2 3
		echo -n "."
		set failed no
		if findmnt "$targetDir/proc" > /dev/null
			set err1 (umount --recursive "$targetDir/proc" 2>&1) || set failed yes
		end
		if findmnt "$targetDir/sys" > /dev/null
			set err2 (umount --recursive "$targetDir/sys" 2>&1) || set failed yes
		end
		if findmnt "$targetDir/dev" > /dev/null
			set err3 (umount --recursive "$targetDir/dev" 2>&1) || set failed yes
		end
		if [ "$failed" = "no" ]
			break
		end
		sleep 1
	end
	echo
	if [ "$failed" = "yes" ]
		echo "failed:"
		if [ "$err1" != "" ]
			echo "proc:"
			echo "$err1"
		end
		if [ "$err2" != "" ]
			echo "sys:"
			echo "$err2"
		end
		if [ "$err3" != "" ]
			echo "dev:"
			echo "$err3"
		end
	end
end
