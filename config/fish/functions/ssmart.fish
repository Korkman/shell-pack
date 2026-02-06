#! /usr/bin/env -S fish -c ssmart

# super smartctl
function ssmart
	if test "$argv[1]" = ""
		echo "ssmart will 'smartctl -x | less' for a device name"
		echo "arg #1: device name (/dev may be omitted) required"
		return 1
	end
	
	set -l dev "$argv[-1]"
	if ! test -b "$dev" && ! string match '/*' "$dev"
		# not an absolute path, does not exist: fix up path
		if test -b "/dev/$dev"
			# try prepend /dev/
			set dev "/dev/$dev"
		end
	end
	
	# pipe smartctl to less, highlighting key lines, jump to end then jump to start (working around bell when already at start)
	set -l cmd
	if ! test -r "$dev"
		set -a cmd "sudo"
	end
	set -a cmd smartctl $argv[1..-2] -x "$dev"
	
	$cmd | __sp_pager '+/.*(smartctl [0-9]|overall-health self-assessment|Reallocated_Sector_Ct|Wear_Leveling_Count|Uncorrectable_Error_Cnt|Seek_Error_Rate|Power_On_Hours|Current_Pending_Sector|Media_Wearout_Indicator|Reported_Uncorrect|Available Spare|Data Units Written|Power On Hours|Media and Data Integrity Errors|Test_Description|Raw_Read_Error_Rate|% of test remaining).*$' '+G' '+g'
end
