function __polyfill_flock -d \
	"Installs a bad polyfill for flock if needed."
	if ! command -sq flock
		if command -sq shlock
			function flock -d \
				"A bad polyfill for flock, needed on macOS (and illumOS?). Supports only first form."
				set lockfile "$argv[1]"".shlock"
				set mod_argv $argv
				set -e mod_argv[1]
				
				while ! shlock -f "$lockfile" -p $fish_pid
					sleep 0.2
				end
				eval $mod_argv
				rm "$lockfile"
			end
		else
			echo "Neither flock not shlock installed. Bailing out!"
			sleep 2
			# leaving flock undefined
		end
	end
	
	function __polyfill_flock
	end
end
