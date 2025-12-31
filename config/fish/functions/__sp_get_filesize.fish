function __sp_get_filesize -a file -d \
	'Get filesize in bytes'
	set -l output (command ls -nl "$file" | string split --no-empty ' ')
	and echo "$output[5]"
end
