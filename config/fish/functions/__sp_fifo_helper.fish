function __sp_fifo_helper -d \
	"Helper to set up a FIFO buffered process outside of FISH. Outputs PID and FIFO path. Pass command and args as is."
	# See https://github.com/fish-shell/fish-shell/issues/7422
	set -lx FIFO (__sp_mkuniq --dry-run --xdg-runtime "shell-pack-fifo-XXXXXX")
	mkfifo "$FIFO"
	sh -c '"$@" > "$FIFO" & echo "$!"' __sp_fifo_helper_sh $argv
	echo "$FIFO"
end
