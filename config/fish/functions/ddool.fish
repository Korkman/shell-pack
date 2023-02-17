#! /usr/bin/env -S fish -c ddool

# das dool with sane default parameters and auto-saved pass-thru params
function ddool -w dool
	if test "$argv[1]" = "--clear"
		set -U ddstat_addon_params ""
	end
	if test "$argv" != "" -a "$argv[1]" != "--help"
		set -U ddstat_addon_params "$argv"
	end
	if test "$ddstat_addon_params" != ""
		echo "Starting ddool $ddstat_addon_params"
	end
	eval "dool -cdrn --tcp --time $ddstat_addon_params"
end
