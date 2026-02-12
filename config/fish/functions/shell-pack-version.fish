function shell-pack-version \
-d "Returns the current shell-pack-version"
	# not a variable anymore!
	# advantage: new shell-pack-releases that don't touch config.fish
	# won't cause reloads anymore!
	
	# NOTE: the following line is parsed by legacy versions (<= 3.31) of shell-pack-check-upgrade!
	echo '3.40'
end
