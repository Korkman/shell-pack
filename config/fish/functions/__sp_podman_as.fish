# run podman as the owner of PID (rootless podman containers are invisible to other users, even root)
function __sp_podman_as -a pid
	set -e argv[1]
	set -l uid (awk '/^Uid:/ { print $2; exit }' /proc/$pid/status 2>/dev/null)
	if test -z "$uid"; or test "$uid" = (id -u)
		command podman $argv
		return
	end
	if test (id -u) != 0
		# cannot switch users, nothing to be seen
		return 1
	end
	set -l user (id -nu $uid 2>/dev/null)
	test -n "$user"; or return 1
	set -l runner
	if command -q runuser
		set runner runuser -u $user --
	else if command -q sudo
		set runner sudo -n -u $user
	else
		return 1
	end
	$runner env XDG_RUNTIME_DIR=/run/user/$uid HOME=(getent passwd $uid | string split -f6 :) sh -c 'cd / && exec podman "$@"' sh $argv
end
