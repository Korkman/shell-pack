#! /usr/bin/env -S fish -c ddstat

# das dstat with sane default parameters and auto-saved pass-thru params
function ddstat -w dstat
	if test "$argv[1]" = "--clear"
		set -U ddstat_addon_params ""
	end
	if test "$argv" != "" -a "$argv[1]" != "--help"
		set -U ddstat_addon_params "$argv"
	end
	if test "$ddstat_addon_params" != ""
		echo "Starting ddstat $ddstat_addon_params"
	end
	eval "dool -cdrn --tcp --time $ddstat_addon_params"
end
