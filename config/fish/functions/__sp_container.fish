# print the name (or short ID) of the docker/podman container owning PID, "-" if none; PORT is the local port (optional)
function __sp_container -a pid -a port
	if not string match -qr '^[0-9]+$' -- $pid
		echo -
		return
	end
	set -l cgroup (cat /proc/$pid/cgroup 2>/dev/null)
	set -l id (string match -rg '([0-9a-f]{64})' -- $cgroup)[1]
	if test -z "$id"
		__sp_container_proxied $pid $port
		return
	end
	# podman names its cgroup scopes libpod-<id>, docker uses /docker/<id> or docker-<id>
	set -l engine docker
	if string match -q '*libpod*' -- $cgroup
		set engine podman
	end
	set -l name
	if command -q $engine
		set name (command $engine inspect --format '{{.Name}}' $id 2>/dev/null)
	end
	if test -n "$name[1]"
		# docker reports names with a leading slash
		string replace -r '^/' '' -- $name[1]
	else
		string sub -l 12 -- $id
	end
end
