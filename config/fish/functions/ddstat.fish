#! /usr/bin/env -S fish -c ddstat

# das dstat with sane default parameters and auto-saved pass-thru params
function ddstat -w dstat
	# if not set, set default base parameters
	if test -z "$ddstat_base_args"
		set -f ddstat_base_args --time -cdrn
	end
	
	if test "$argv[1]" = "--help"; or test "$argv[1]" = "-h"
		# pass to dstat
		dstat --help
		# append help text
		echo "----------------------------------------"
		echo ""
		echo "ddstat persists arguments for dstat, so next time you run ddstat, it will"
		echo "pass the same arguments."
		echo ""
		echo "Usage: ddstat [dstat arguments]"
		echo "       ddstat --append [dstat arguments]"
		echo "       ddstat --remove [dstat arguments]"
		echo "       ddstat --clear"
		echo "       ddstat INTERVAL"
		echo ""
		echo "--append / --remove can be used to add or remove select arguments"
		echo ""
		echo "--clear clears all saved arguments"
		echo ""
		echo "Just passing an interval will not save it"
		echo ""
		echo "Default arguments added are $ddstat_base_args, which can be overridden:"
		echo "set -U ddstat_base_args $ddstat_base_args"
		echo "or reset:"
		echo "set -eU ddstat_base_args"
		return
	end
	
	if test "$argv[1]" = "--clear"
		set -eU ddstat_addon_params
		echo "Cleared saved dstat arguments. \$ddstat_base_args:"
		echo "$ddstat_base_args"
		return
	end
	
	if test "$argv[1]" = "--append"
		# shift argv to get remaining arguments, append them to $ddstat_addon_params
		set argv $argv[2..-1]
		# iterate over arguments and append them
		# only if string wasn't already appended
		if ! string match -q -- "$argv" "$ddstat_addon_params"
			for arg in $argv
				set -U -a ddstat_addon_params "$arg"
			end
		end
		# remove all arguments for remaining processing
		set -e argv
	end
	
	if test "$argv[1]" = "--remove"
		# shift argv to get remaining arguments, remove them from $ddstat_addon_params
		set argv $argv[2..-1]
		set -U ddstat_addon_params (string replace -r -- $argv $ddstat_addon_params)
		# remove all arguments for remaining processing
		set -e argv
	end
	
	# if only an interval is passed, do not persist it
	set -l ddstat_temp_args
	if string match -q --regex -- '^([0-9]+)$' "$argv"
		set -a ddstat_temp_args "$argv"
		set -e argv
	end
	
	# persist arguments
	if test "$argv" != ""
		set -U ddstat_addon_params $argv
	end
	
	# print arguments as passed to dstat
	echo -n "dstat"
	for arg in $ddstat_base_args $ddstat_addon_params $ddstat_temp_args
		echo -n " "(string escape --style script -- $arg)
	end
	echo ""
	dstat $ddstat_base_args $ddstat_addon_params $ddstat_temp_args
end
