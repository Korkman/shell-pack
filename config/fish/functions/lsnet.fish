#! /usr/bin/env -S fish -c lsnet

function lsnet -d \
"List network connections, program names and process IDs"
  if test "$argv[1]" = "--help"
    echo "Usage: lsnet"
    echo
    echo -e (functions -vD (status current-function))[5]
    return 1
  end >&2
  
  # estimated max width of 2* (IPv6 + 5 digit port + 6 chr interface) + "tcp" = 110
  set -l procWidth (math $COLUMNS-110)
  if $__cap_ss
    if test "$procWidth" -gt 20
      __lsnet_ss_rows $procWidth | sort -k3 | awk 'BEGIN { print "Local", "Remote", "Processes", "Type", "UID", "Container"} {print $0}' | __sp_column_t
    else
      # narrow display
      set procWidth (math $COLUMNS-3)
      __lsnet_ss_rows $procWidth | awk '{ print $1,$2,$4,$5; print " ", $3; if ($6 != "-") print "  Container:", $6 }' | awk 'BEGIN { print "Local", "Remote", "Type", "UID"; print "Processes" } {print $0}'
    end
  else
		# netstat (macos) edition
		__lsnet_netstat_headered | __sp_column_t
  end
end

# one line per connection: local, remote, processes, type, uid, container
function __lsnet_ss_rows -a width
  # ss prints a harmless "RTNETLINK answers: Invalid argument" on stderr; the connection list is complete
  ss -np -A inet 2>/dev/null | tail -n+2 | ss_procfilter | awk -v w=$width '{ pid = "-"; if (match($7, /\[[0-9]+/)) pid = substr($7, RSTART + 1, RLENGTH - 1); print $5, $6, ($7 == "" ? "-" : substr($7, 0, w)), $1, pid }' | while read -l local remote proc type pid
    set -l ctr (__sp_container $pid (string replace -r '.*:' '' -- $local))
    test "$ctr" = -; and set ctr (__sp_container_remote $pid $remote)
    set -l uid (awk '/^Uid:/ { print $2; exit }' /proc/$pid/status 2>/dev/null)
    echo "$local $remote $proc $type "(test -n "$uid"; and echo $uid; or echo -)" $ctr"
  end
end

function __lsnet_netstat_headered
	echo "Local Remote  Pid	Type"
	set -l -a netdata (__lsnet_netstat | sort | uniq)
	for line in $netdata
		# TODO: ps -p PID, reformat like ss version
		# TODO: combine multiple PIDs to single line
		echo $line
	end
end

function __lsnet_netstat
	netstat -nv -f inet | grep -i established | awk "{ print \$4,\$5,\$9,\$1 }"
	netstat -nv -f inet6 | grep -i established | awk "{ print \$4,\$5,\$9,\$1 }"
end
