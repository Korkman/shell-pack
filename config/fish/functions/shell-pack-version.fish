function shell-pack-version \
-d "Returns the current shell-pack-version"
	# not a variable anymore!
	# advantage: new shell-pack-releases that don't touch config.fish
	# won't cause reloads anymore!
	
	echo '2.2'
end
