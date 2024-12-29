#! /usr/bin/env -S fish -c ddool

# das dool with sane default parameters and auto-saved pass-thru params
function ddool -w dool
	# if not set, set default base parameters
	if test -z "$ddool_base_args"
		set -f ddool_base_args --bytes --time -cdrn
	end
	
	if test "$argv[1]" = "--help"; or test "$argv[1]" = "-h"
		# pass to dool
		dool --help
		# append help text
		echo "----------------------------------------"
		echo ""
		echo "ddool persists arguments for dool, so next time you run ddool, it will"
		echo "pass the same arguments."
		echo ""
		echo "Usage: ddool [dool arguments]"
		echo "       ddool --append [dool arguments]"
		echo "       ddool --remove [dool arguments]"
		echo "       ddool --clear"
		echo "       ddool INTERVAL"
		echo ""
		echo "--append / --remove can be used to add or remove select arguments"
		echo ""
		echo "--clear clears all saved arguments"
		echo ""
		echo "Just passing an interval will not save it"
		echo ""
		echo "Default arguments added are $ddool_base_args, which can be overridden:"
		echo "set -U ddool_base_args $ddool_base_args"
		echo "or reset:"
		echo "set -eU ddool_base_args"
		return
	end
	
	# convert legacy variable $ddstat_addon_params to $ddool_addon_args
	if test -z "$ddool_addon_args"
		if test -n "$ddstat_addon_params"
			set -U ddool_addon_args "$ddstat_addon_params"
			set -eU ddstat_addon_params
		end
	end
	
	if test "$argv[1]" = "--clear"
		set -eU ddool_addon_args
		set -eU ddstat_addon_params
		echo "Cleared saved dool arguments. \$ddool_base_args:"
		echo "$ddool_base_args"
		return
	end
	
	if test "$argv[1]" = "--append"
		# shift argv to get remaining arguments, append them to $ddool_addon_args
		set argv $argv[2..-1]
		# iterate over arguments and append them
		# only if string wasn't already appended
		if ! string match -q -- "$argv" "$ddool_addon_args"
			for arg in $argv
				set -U -a ddool_addon_args "$arg"
			end
		end
		# remove all arguments for remaining processing
		set -e argv
	end
	
	if test "$argv[1]" = "--remove"
		# shift argv to get remaining arguments, remove them from $ddool_addon_args
		set argv $argv[2..-1]
		set -U ddool_addon_args (string replace -r -- "$argv" "$ddool_addon_args")
		# remove all arguments for remaining processing
		set -e argv
	end
	
	# if only an interval is passed, do not persist it
	set -l ddool_temp_args
	if string match -q --regex -- '^([0-9]+)$' "$argv"
		set -a ddool_temp_args "$argv"
		set -e argv
	end
	
	# persist arguments
	if test "$argv" != ""
		set -U ddool_addon_args $argv
	end
	
	# print arguments as passed to dool
	echo -n "dool"
	for arg in $ddool_base_args $ddool_addon_args $ddool_temp_args
		echo -n " "(string escape --style script -- "$arg")
	end
	echo ""
	dool $ddool_base_args $ddool_addon_args $ddool_temp_args
end
