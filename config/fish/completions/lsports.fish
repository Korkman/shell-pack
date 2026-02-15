# general/help
complete -c lsports -f -s h -l help -d 'Show usage/help'

# nmap-related presets
complete -c lsports -f -l quiet -d 'Disable nmap verbosity'
complete -c lsports -f -l udp -d 'Scan UDP ports instead of TCP'
complete -c lsports -f -l tcp -d 'Scan TCP ports (default)'
complete -c lsports -f -l probe -d 'Enable service and OS detection'
complete -c lsports -f -l slow -d 'Slow down scan'
complete -c lsports -f -l patience -d 'Disable default host timeout'
complete -c lsports -f -l ping -d 'Perform a ping scan only'

# visibility of the simplified wrapper options is priorized
#complete -c lsports -f -w nmap
