function hostname
	# the polyfill self-destructs when the native command becomes available
	if command -q hostname
		functions -e hostname
		command hostname $argv
		return
	end

	# polyfill in case "hostname" is not available
	argparse \
		'f/fqdn' \
		's/short' \
		'h/help' \
		'V/version' \
		-- $argv
	or return 1

	if set -q _flag_help
		echo "Usage: hostname [-fsV]"
		return 0
	end

	if set -q _flag_version
		echo "hostname 0.01 (shell-pack polyfill)"
		return 0
	end

	# Read kernel hostname portably: Linux proc → sysctl (BSD/macOS) → /etc/hostname
	function _hn_get
		set -l h (cat /proc/sys/kernel/hostname 2>/dev/null | string trim)
		if test -z "$h"; and command -q sysctl
			set h (sysctl -n kern.hostname 2>/dev/null | string trim)
		end
		if test -z "$h"
			set h (cat /etc/hostname 2>/dev/null | string trim)
		end
		echo $h
	end

	set -l kernel_hostname (_hn_get)
	if test -z "$kernel_hostname"
		echo "hostname: unable to determine hostname" >&2
		return 1
	end

	# -s: strip everything from first dot onward
	if set -q _flag_s
		echo $kernel_hostname | string replace -r '\..*' ''
		return 0
	end

	# -f: resolve FQDN from /etc/hosts
	if set -q _flag_f
		set -l fqdn (awk -v h=$kernel_hostname '
			!/^#/ && $0 ~ h {
				for (i=2; i<=NF; i++) if ($i ~ /\./) { print $i; exit }
			}
		' /etc/hosts 2>/dev/null)
		echo (test -n "$fqdn"; and echo $fqdn; or echo $kernel_hostname)
		return 0
	end

	# Default: print hostname
	echo $kernel_hostname
end
