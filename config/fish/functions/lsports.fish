#! /usr/bin/env -S fish -c lsports

# show listening inet sockets
# NOTE: tail can be replaced with ss -H when xenial and jessie faded away
function lsports
	# any arguments passed are treated as nmap args
	if test "$argv" != ""
		if contains -- "--help" $argv || contains -- "-h" $argv
			echo "Usage: lsports"
			echo "  Without arguments, shows listening processes on the local machine"
			echo "  as reported by ss or netstat."
			echo
			echo "Usage: lsports [ nmap args ... ] HOST/NETWORK"
			echo "  With arguments, performs an nmap scan of the specified host or network."
			echo "  DO NOT SCAN NETWORKS OR HOSTS WITHOUT PERMISSION."
			echo "  Arguments are passed after defaults, which are to perform a verbose,"
			echo "  TCP-only scan of all ports with a time limit of 300s per host."
			return
		end
		
		echo "IP scan requested"
		if command -q nmap
			set -l -- nmap_args -p- -v -n --host-timeout 300s $argv
			# auto-prepend -6 if last arg looks like IPv6 address and -6 is not already present
			if string match -q -- "*:*" "$nmap_args[-1]" && not contains -- "-6" $nmap_args
				set -p nmap_args "-6"
			end
			nmap $nmap_args
		else
			echo "nmap not found, cannot perform IP scan"
			return 1
		end
		return
	end
	# estimated max width of IPv6 + 5 digit port + 6 chr interface + "tcp" = 57
	set procWidth (math $COLUMNS-58)
	if $__cap_ss
		if test "$procWidth" -gt 20
			ss -nlp -A inet | tail -n+2 | ss_procfilter | awk "{ print \$5,substr(\$7, 0, $procWidth),\$1}" | sort -k2 | awk 'BEGIN { print "Listen", "Processes", "Type"} { print $0 }' | __sp_column_t | uniq
		else
			# narrow display
			set procWidth (math $COLUMNS-3)
			ss -nlp -A inet | tail -n+2 | ss_procfilter | awk "{ print \$5,\$1; print \" \", substr(\$7, 0, $procWidth)}" | awk 'BEGIN { print "Listen", "Type"; print "Processes"} { print $0 }' | uniq
		end
	else
		# netstat (macos) edition
		__lsports_netstat_headered | __sp_column_t
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
