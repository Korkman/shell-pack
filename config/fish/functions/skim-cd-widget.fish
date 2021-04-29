function skim-cd-widget -d "Change directory (recusrive search)"
	# NOTE: the behavior is very different from the original skim-cd-widget-one
	# - it does not substitute the last token of the command with the
	#   arrival directory, nor does it search for it
	# - the commandline stays untouched, so you can chdir without ctrl-c

	if [ "$argv[1]" = "--dotfiles" ]
		skim-dotfiles yes
	else
		skim-dotfiles no
	end

	set -l dir '.'
	set -l skim_query ''

	set -q SKIM_ALT_C_COMMAND; or set -l SKIM_ALT_C_COMMAND "
	command find -L \$dir -xdev -mindepth 1 \\( $SKIM_DOTFILES_FILTER \\) -prune \
	-o -type d -print 2> /dev/null | sed 's@^\./@@'"

	set -q SKIM_TMUX_HEIGHT; or set SKIM_TMUX_HEIGHT 40%
	begin
		set -lx SKIM_DEFAULT_OPTIONS "--height $SKIM_TMUX_HEIGHT --reverse $SKIM_DEFAULT_OPTIONS $SKIM_ALT_C_OPTS"
		eval "$SKIM_ALT_C_COMMAND | "(__skimcmd)' --header "'skim recursive cd. search for and select dir or esc to abort.'" -m --query "'$skim_query'"' | read -l result

		if [ -n "$result" ]
			cd "$result"
		end
	end

	commandline -f repaint
end
