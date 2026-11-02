# resolve the rootless podman container that opened a connection to REMOTE (addr:port), via the shared rootless-netns pasta; "-" if none
function __sp_container_remote -a pid -a remote
	if not string match -qr '^[0-9]+$' -- $pid
		echo -
		return
	end
	set -l cmdline (tr '\0' ' ' </proc/$pid/cmdline 2>/dev/null)
	if not string match -q -- '*rootless-netns*' $cmdline; or not command -q podman
		echo -
		return
	end
	# one line per running container: name, then its network namespace
	set -l info (__sp_podman_as $pid inspect --format '{{.Name}} {{.NetworkSettings.SandboxKey}}' (__sp_podman_as $pid ps -q 2>/dev/null) 2>/dev/null)
	for line in $info
		set -l fields (string split ' ' -- $line)
		# container netns is owned by the user namespace, so enter it through podman unshare
		set -l peers (__sp_podman_as $pid unshare nsenter --net=$fields[2] ss -Htn state established 2>/dev/null | awk '{ print $NF }')
		if contains -- $remote $peers
			echo $fields[1]
			return
		end
	end
	echo -
end
