#! /usr/bin/env -S fish -c ssmart

function ssmart -d "Pages 'smartctl -x' output for a device"
	
	if ! set -q argv[1] || test "$argv[1]" = '--help'
		echo "Usage: ssmart [ OPTIONS ... ] DEVICE"
		echo
		echo -e (functions -vD (status current-function))[5]
		echo
		echo "Extra OPTIONS are passed directly to smartctl."
		echo "Key values of interest are highlighted in output."
		echo 
		echo "Tip: Use tab completion to list available devices."
		echo "Also: /dev/ can be omitted from DEVICE."
		return 1
	end >&2
	
	set -l dev $argv[-1]
	if ! test -b "$dev" && ! string match '/*' "$dev"
		# not an absolute path, does not exist: fix up path
		if test -b "/dev/$dev"
			# try prepend /dev/
			set dev "/dev/$dev"
		end
	end
	
	set -l cmd
	# prepend sudo if we are not root (write permissions do not suffice, we need capabilities)
	if test (id -u) -ne 0
		set -a cmd "sudo"
	end
	set -a cmd smartctl $argv[1..-2] -x "$dev"
	
	# pipe smartctl, highlight key lines with rg, page with __sp_pager
	$cmd | rg --color=always --passthru '.*(smartctl [0-9]|overall-health self-assessment|Reallocated_Sector_Ct|Wear_Leveling_Count|Uncorrectable_Error_Cnt|Seek_Error_Rate|Power_On_Hours|Current_Pending_Sector|Media_Wearout_Indicator|Reported_Uncorrect|Available Spare|Data Units Written|Power On Hours|Media and Data Integrity Errors|Test_Description|Raw_Read_Error_Rate|% of test remaining).*' | __sp_pager
end
