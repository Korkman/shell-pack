# resolve the container behind a port forwarder (docker-proxy, rootless podman pasta/rootlessport), "-" if none
function __sp_container_proxied -a pid -a port
	set -l cmdline (tr '\0' ' ' </proc/$pid/cmdline 2>/dev/null)
	# rootless podman: pasta is started with the container's network namespace
	set -l netns (string match -rg -- '--netns (\S+)' $cmdline)[1]
	if test -n "$netns"
		if not command -q podman
			echo -
			return
		end
		set -l info (__sp_podman_as $pid inspect --format '{{.Name}} {{.NetworkSettings.SandboxKey}}' (__sp_podman_as $pid ps -q 2>/dev/null) 2>/dev/null)
		for line in $info
			set -l fields (string split ' ' -- $line)
			if test "$fields[2]" = "$netns"
				echo $fields[1]
				return
			end
		end
		echo -
		return
	end
	# rootless podman with published ports: rootlessport has no netns argument, match the host port instead
	if string match -qr '(^|/)rootlessport( |$)' -- $cmdline; and test -n "$port"; and command -q podman
		for line in (__sp_podman_as $pid ps --format '{{.Names}} {{.Ports}}' 2>/dev/null)
			if string match -q -- "*:$port->*" $line
				echo (string split -m1 ' ' -- $line)[1]
				return
			end
		end
		echo -
		return
	end
	# docker-proxy: resolve the container by the IP it forwards to
	set -l cip (string match -rg -- '-container-ip (\S+)' $cmdline)[1]
	if test -z "$cip"; or not command -q docker
		echo -
		return
	end
	# one line per running container: name, then its network addresses
	set -l info (command docker inspect --format '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}} {{.GlobalIPv6Address}} {{end}}' (command docker ps -q 2>/dev/null) 2>/dev/null)
	for line in $info
		set -l fields (string split ' ' -- $line)
		if contains -- $cip $fields
			string replace -r '^/' '' -- $fields[1]
			return
		end
	end
	echo -
end
