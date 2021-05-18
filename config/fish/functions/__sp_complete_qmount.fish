function __sp_complete_qmount -d \
	"Autocomplete for qmount, listing all currently unmounted blockdevices"
	
	# NOTE: jq would be a better option here, but I don't feel like introducing this dependency now

	set -l lsblk_out

	# while debian jessie is still around, use the --pairs edition
	# detect --json edition

	if lsblk --help | grep -q "\--json"
		set lsblk_out (command lsblk --nodeps --inverse --paths --output NAME,SIZE,TYPE,MOUNTPOINT,LABEL,PARTLABEL,FSTYPE --json) || return 1

		# sanity checks for --json
		if test "$lsblk_out[1]" != "{"; return 2; end
		if test "$lsblk_out[2]" != '   "blockdevices": ['; return 3; end

		# WARNING: regular expression not for the faint hearted

		function __sp_complete_qmount_lineparser -S
			string match --regex -q '^      \{'\
'"name": ?"(?<name>.*)"'\
', "size": ?"(?<size>.*)"'\
', "type": ?"(?<type>.*)"'\
', "mountpoint": ?("(?<mountpoint>.*)"|null)'\
', "label": ?("(?<label>.*)"|null)'\
', "partlabel": ?("(?<partlabel>.*)"|null)'\
', "fstype": ?("(?<fstype>.*)"|null)'\
'\}?,?' -- "$line"
		end

	else
		# using lsblk --json and parsing it with regex
		set lsblk_out (command lsblk --nodeps --inverse --paths --output NAME,SIZE,TYPE,MOUNTPOINT,LABEL,PARTLABEL,FSTYPE --pairs) || return 1

		function __sp_complete_qmount_lineparser -S
			string match --regex -q '^'\
'NAME="(?<name>.*)"'\
' SIZE="(?<size>.*)"'\
' TYPE="(?<type>.*)"'\
' MOUNTPOINT="(?<mountpoint>.*)"'\
' LABEL="(?<label>.*)"'\
' PARTLABEL="(?<partlabel>.*)"'\
' FSTYPE="(?<fstype>.*)"'\
'' -- "$line"
		end

	end

	
	for line in $lsblk_out[1..]
		# only accept lines with this prefix and indent
		set -le identifiers

		set -l name ""
		set -l size ""
		set -l type ""
		set -l mountpoint ""
		set -l label ""
		set -l partlabel ""
		set -l fstype ""
		
		if __sp_complete_qmount_lineparser
			# debug outputs
			#echo "$line"
			#echo "name: "(string escape -- $name)
			#echo "size: "(string escape -- $size)
			#echo "type: "(string escape -- $type)
			#echo "mountpoint: "(string escape -- $mountpoint)
			
			set -l identifiers ""
			if test "$label" != "";     set identifiers "$identifiers""$label | "; end
			if test "$partlabel" != ""; set identifiers "$identifiers""$partlabel | "; end
			if test "$fstype" != ""; set identifiers "$identifiers""$fstype | "; end
			
			set identifiers "$identifiers""$size"
			
			set identifiers (string trim $identifiers)
			if test "$mountpoint" = ""
				# only suggest unmounted options
				echo "$name"\t"$identifiers"
			end
		end
	end
end
