function __sp_get_diskimages_completion
	set -l extmatch '\.(?<ext>(vhd|vmdk|vdi|vhdx|qcow2|qed|dd|raw|img|hdd|iso|bin|sfs|squash|squashfs))$'
	# echo detected file extensions first
	for i in *
		if ! test -f $i
			continue
		end
		if string match -qir $extmatch -- "$i"
			echo "$i"\t"$ext"
		end
	end | sort
	
	# maybe don't output other files?
	#for i in *
	#	if ! test -f $i
	#		continue
	#	end
	#	if string match -qir $extmatch -- "$i"
	#		continue
	#	end
	#	echo "$i"\t"file"
	#end | sort
end
complete --no-files --command qmount --keep-order --arguments "(__sp_get_blockdevice_completion --mountable --unmounted; __sp_get_diskimages_completion)" 
