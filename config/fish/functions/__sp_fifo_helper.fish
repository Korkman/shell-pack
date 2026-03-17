function __sp_fifo_helper -d \
	"Helper to set up a FIFO buffered process outside of FISH. Outputs PID and FIFO path. Pass command and args as is."
	# See https://github.com/fish-shell/fish-shell/issues/7422
	set -l tmpdir
	if test "$XDG_RUNTIME_DIR" != "" && test -e "$XDG_RUNTIME_DIR"
		set tmpdir "$XDG_RUNTIME_DIR"
	else if test "$TMPDIR" != "" && test -e "$TMPDIR"
		set tmpdir "$TMPDIR"
	else
		set tmpdir "/tmp"
	end
	set -lx FIFO (mktemp -u "$tmpdir/shell-pack-fifo-XXXXXX")
	mkfifo "$FIFO"
	sh -c '"$@" > "$FIFO" & echo "$!"' __sp_fifo_helper_sh $argv
	echo "$FIFO"
end
