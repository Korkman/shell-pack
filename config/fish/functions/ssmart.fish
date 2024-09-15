#! /usr/bin/env -S fish -c ssmart

# super smartctl
function ssmart
  if test "$argv[1]" = ""
    echo "ssmart will 'smartctl -x | less' for a device name"
    echo "arg #1: device name (/dev may be omitted) required"
    return 1
  end
  
  set -l dev "$argv[-1]"
  
  smartctl $argv[1..-2] -x $dev | less '+/.*(Reallocated_Sector_Ct|Wear_Leveling_Count|Uncorrectable_Error_Cnt|Seek_Error_Rate|Power_On_Hours|Current_Pending_Sector|Available Spare|Data Units Written|Power On Hours|Media and Data Integrity Errors).*$' +g
end
