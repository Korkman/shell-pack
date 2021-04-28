#! /usr/bin/env -S fish -c lsnet

# ssshow outgoing inet sockets
function lsnet
  # estimated max width of 2* (IPv6 + 5 digit port + 6 chr interface) + "tcp" = 110
  set -l procWidth (math $COLUMNS-110)
  if $__cap_ss
    if test "$procWidth" -gt 20
      ss -np -A inet | tail -n+2 | ss_procfilter | awk "{print \$5,\$6,substr(\$7, 0, $procWidth),\$1}" | sort -k3 | awk 'BEGIN { print "Local", "Remote", "Processes", "Type"} {print $0}' | column -t
    else
      # narrow display
      set procWidth (math $COLUMNS-3)
      ss -np -A inet | tail -n+2 | ss_procfilter | awk "{print \$5,\$6,\$1; print \" \", substr(\$7, 0, $procWidth)}" | awk 'BEGIN { print "Local", "Remote", "Type"; print "Processes" } {print $0}'
    end
  else
		# netstat (macos) edition
		__lsnet_netstat_headered | column -t
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
