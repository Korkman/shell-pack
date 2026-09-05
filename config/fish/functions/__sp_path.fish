function __sp_path
	argparse 'r/xdg-runtime' 't/global-tmp' -- $argv
	or return 1
	
	if set -q _flag_xdg_runtime
		if test "$XDG_RUNTIME_DIR" = "" || ! test -w "$XDG_RUNTIME_DIR"
			# else fall back to a TMPDIR subdirectory
			set XDG_RUNTIME_DIR (__sp_path --global-tmp)"/.sp-runtime-dir-$EUID"
			if ! test -w "$XDG_RUNTIME_DIR"
				mkdir "$XDG_RUNTIME_DIR"
				chmod 0700 "$XDG_RUNTIME_DIR"
			end
		end
		echo "$XDG_RUNTIME_DIR"
		return 0
	end
	
	if set -q _flag_global_tmp
		if test "$TMPDIR" = ""
			set TMPDIR "/tmp"
		end
		echo "$TMPDIR"
		return 0
	end
	
	return 1
end
