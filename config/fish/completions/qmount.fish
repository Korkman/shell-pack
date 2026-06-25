function __sp_get_diskimages_completion
	set -l extmatch '\.(?<ext>(vhd|vmdk|vdi|vhdx|qcow|qcow2|qed|dd|raw|img|hdd|iso|bin|sfs|squash|squashfs|dmg|cloop))$'
	# echo detected file extensions first
	for i in *
		if ! test -f "$i"
			continue
		end
		if string match -qir $extmatch -- "$i"
			echo "$i"\t"$ext"
		end
	end | sort
end
complete --command qmount --no-files --long-option ro     --description "Mount read-only at block device level (default)"
complete --command qmount --no-files --long-option rw     --description "Mount read-write at block device level"
complete --command qmount --long-option tmp-rw --description "Redirect writes to temporary overlay; optionally =FILE for persistent qcow2 overlay"
complete --command qmount --keep-order --arguments "(__sp_get_blockdevice_completion --mountable --unmounted; __sp_get_diskimages_completion)" 
