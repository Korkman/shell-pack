# this function will adapt to the local system and return hex formatted md5 sum for a given file.
function __sp_getmd5 -a file -d \
	'Get md5 sum of a file (normalized, self-redefining)'
	if command -sq md5sum
		function __sp_getmd5 -a file -d \
			'Get md5 sum of a file (normalized, detected md5sum)'
			if test "$file" != ""
				md5sum "$file" | string replace --regex -- ' .*' '' | string collect
			else
				md5sum | string replace --regex -- ' .*' '' | string collect
			end
		end
		__sp_getmd5 "$file"
	else if command -sq md5
		function __sp_getmd5 -a file -d \
			'Get md5 sum of a file (normalized, detected md5)'
			if test "$file" != ""
				md5 "$file" | string replace --regex -- '.* = ' '' | string collect
			else
				md5 | string replace --regex -- ' .*' '' | string collect
			end
		end
		__sp_getmd5 "$file"
	else
		echo "FATAL ERROR: neither md5 nor md5sum installed, exiting"
		exit 99
	end
end

