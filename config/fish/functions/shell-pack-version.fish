function shell-pack-version \
-d "Returns the current shell-pack-version"
	# not a variable anymore!
	# advantage: new shell-pack-releases that don't touch config.fish
	# won't cause reloads anymore!
	
	# NOTE: the following line is parsed by shell-pack-check-upgrade!
	echo '2.28'
end
