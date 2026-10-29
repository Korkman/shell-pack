function td -d \
	"Test-drive functions for development"
	argparse --stop-nonopt 'h/help' -- $argv
	or return 2
	set -l verb $argv[1]
	if set -q _flag_help
		set verb help
	end

	set fname "td-$verb"
	if set -q _flag_help || ! functions -q "$fname"
		echo "Usage: td SUBCOMMAND [args...]"
		echo
		echo "Subcommands:"
		for subcommand in (__sp_td_subcommands | sort)
			# functions --details --verbose always emits 5 fields; the 5th is the description
			set -l desc (functions --details --verbose "td-$subcommand")[5]
			printf '  %-10s %s\n' "$subcommand" "$desc"
		end
		set -q _flag_help
		and return 0
		or return 1
	end >&2
	$fname $argv[2..-1]
end
