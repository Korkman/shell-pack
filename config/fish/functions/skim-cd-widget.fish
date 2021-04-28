function skim-cd-widget -d "Change directory"
	if [ "$argv[1]" = "--dotfiles" ]
		skim-dotfiles yes
	else
		skim-dotfiles no
	end
	set -l commandline (__skim_parse_commandline)
	set -l dir $commandline[1]
	set -l skim_query $commandline[2]

	set -q SKIM_ALT_C_COMMAND; or set -l SKIM_ALT_C_COMMAND "
	command find -L \$dir -xdev -mindepth 1 \\( $SKIM_DOTFILES_FILTER \\) -prune \
	-o -type d -print 2> /dev/null | sed 's@^\./@@'"

	set -q SKIM_TMUX_HEIGHT; or set SKIM_TMUX_HEIGHT 40%
	begin
		set -lx SKIM_DEFAULT_OPTIONS "--height $SKIM_TMUX_HEIGHT --reverse $SKIM_DEFAULT_OPTIONS $SKIM_ALT_C_OPTS"
		eval "$SKIM_ALT_C_COMMAND | "(__skimcmd)' --header "'skim recursive cd. search for and select dir or esc to abort.'" -m --query "'$skim_query'"' | read -l result

		if [ -n "$result" ]
			cd $result

			# Remove last token from commandline.
			commandline -t ""
		end
	end

	commandline -f repaint
end
