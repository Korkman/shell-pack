function __sp_complete_qumount -d \
	"Autocomplete for qumount, listing all currently mounted in /run/q"
	findmnt --output TARGET --raw | string match '/run/q/*'
end
