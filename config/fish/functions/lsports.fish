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
			echo "Usage: lsports [ preset args ] [ nmap args ... ] HOST/NETWORK"
			echo "  With arguments, performs an nmap scan of the specified host or network."
			echo "  DO NOT SCAN NETWORKS OR HOSTS WITHOUT PERMISSION."
			echo "  Arguments are passed after defaults, which are to perform a verbose,"
			echo "  TCP-only scan of all ports with a time limit of 300s per host."
			echo "  Preset args (can be combined):"
			echo "    --quiet   : disable nmap verbosity"
			echo "    --udp     : scan UDP ports instead of TCP"
			echo "    --tcp     : scan TCP ports (default)"
			echo "    --probe   : enable service and OS detection (adds -sV -O)"
			echo "    --slow    : slow down scan to 2 packets/s and increase host timeout to 24h (useful for IDS evasion)"
			echo "    --patience : disable default 300s host timeout"
			return
		end
		
		echo "Remote scan requested - nmap mode"
		if command -q nmap
			# (sane?) defaults: all ports, verbose, no DNS resolution, 300s host timeout 
			set -l -- nmap_args -PE -PP -PM -v -p- -n --host-timeout 300s
			
			if contains -- "--quiet" $argv
				# remove --quiet and -v from args
				set argv (string match -v -- "--quiet" $argv)
				set nmap_args (string match -vr -- "(-v)" $nmap_args)
			end
			if contains -- "--udp" $argv
				# remove --udp from args, set -sU
				set argv (string match -v -- "--udp" $argv)
				set -a nmap_args -sU
			end
			if contains -- "--tcp" $argv
				# remove --tcp from args, set -sS
				set argv (string match -v -- "--tcp" $argv)
				set -a nmap_args -sS
			end
			if contains -- "--probe" $argv
				# remove --probe from args, set -sV
				set argv (string match -v -- "--probe" $argv)
				set -a nmap_args -sV -O
			end
			if contains -- "--slow" $argv
				# remove --slow from args, set --max-rate 1 and --host-timeout 24h
				set argv (string match -v -- "--slow" $argv)
				set nmap_args (string match -vr -- "(--host-timeout|300s)" $nmap_args)
				set -a nmap_args --max-rate 2 --host-timeout 24h
				echo "Slow mode enabled: max 2 packet/s, host timeout 24h"
			end
			if contains -- "--patience" $argv
				# remove --patience and --host-timeout 300s from args
				set argv (string match -v -- "--patience" $argv)
				set nmap_args (string match -vr -- "(--host-timeout|300s)" $nmap_args)
			end
			if contains -- "--ping" $argv
				# remove --ping from args, set -sP
				set argv (string match -v -- "--ping" $argv)
				set nmap_args (string match -v -- "-p-" $nmap_args)
				set -a nmap_args -sP
			end
			# append remaining args (target host/network, overrides)
			set -a nmap_args $argv
			
			set -l retry true
			while $retry
				set retry false
				set -l nmap_output
				echo "nmap $nmap_args"
				nmap $nmap_args &| while read -l line
					echo "$line"
					set -a nmap_output "$line"
					if string match -q -- "*you have to use the -6 option*" "$line"
						echo "Restarting with -6 ..."
						set -p nmap_args "-6"
						set retry true
						continue 2
					end
				end
			end
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
