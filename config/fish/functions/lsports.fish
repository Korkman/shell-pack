#! /usr/bin/env -S fish -c lsports

# show listening inet sockets
# NOTE: tail can be replaced with ss -H when xenial and jessie faded away
function lsports
	# estimated max width of IPv6 + 5 digit port + 6 chr interface + "tcp" = 57
	set procWidth (math $COLUMNS-58)
	if $__cap_ss
		if test "$procWidth" -gt 20
			ss -nlp -A inet | tail -n+2 | ss_procfilter | awk "{ print \$5,substr(\$7, 0, $procWidth),\$1}" | sort -k2 | awk 'BEGIN { print "Listen", "Processes", "Type"} { print $0 }' | column -t | uniq
		else
			# narrow display
			set procWidth (math $COLUMNS-3)
			ss -nlp -A inet | tail -n+2 | ss_procfilter | awk "{ print \$5,\$1; print \" \", substr(\$7, 0, $procWidth)}" | awk 'BEGIN { print "Listen", "Type"; print "Processes"} { print $0 }' | uniq
		end
	else
		# netstat (macos) edition
		__lsports_netstat_headered | column -t
	end
end

function __lsports_netstat_headered
	echo "Listen  Pid	Type"
	set -l -a netdata (__lsports_netstat | sort | uniq)
	for line in $netdata
		# TODO: ps -p PID, reformat like ss version
		# TODO: combine multiple PIDs to single line
		echo $line
	end
end

function __lsports_netstat
	netstat -anv -f inet | grep -i listen | awk "{ print \$4,\$9,\$1 }"
	netstat -anv -f inet6 | grep -i listen | awk "{ print \$4,\$9,\$1 }"
end
