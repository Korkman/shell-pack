function td-override -d \
	"Override a shell-pack function in .config/fish/functions"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help || ! set -q argv[1]
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td override [FUNCTION]"
		echo
		echo "  Override and edit function FUNCTION."
		set -q _flag_help
		and return 0
		or return 1
	end >&2
	
	set fn $argv[1]
	
	mkdir -p "$HOME/.config/fish/functions"
	# copy over or create new function
	if test -e "$HOME/.local/share/shell-pack/config/fish/functions/$fn.fish"
		cp "$HOME/.local/share/shell-pack/config/fish/functions/$fn.fish" "$HOME/.config/fish/functions/$fn.fish"
	else
		echo "NOTE: $fn.fish does not exist, creating a new file"
	end
	# prepend user config to fish_function_path to allow overrides
	if ! string match -q "set -p fish_function_path*" < "$HOME/.config/fish/config.fish"
		echo 'set -p fish_function_path "$HOME/.config/fish/functions"' >> "$HOME/.config/fish/config.fish"
	end
	# start editor
	__sp_editor "$HOME/.config/fish/functions/$fn.fish"
end
