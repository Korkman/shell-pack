function skim-cd-widget-one -d "Change directory one level"
	set -e __skim_cd_widget_one_dotfiles_arg
	if [ "$argv[1]" = "--dotfiles" ]
		set dotfiles_arg "--dotfiles"
		skim-dotfiles yes
	else
		set dotfiles_arg ""
		skim-dotfiles no
	end
	set -l commandline (__skim_parse_commandline)
	set -l dir $commandline[1]
	set -l skim_query $commandline[2]

	set -q SKIM_ALT_C_COMMAND; or set -l SKIM_ALT_C_COMMAND "
	command find -L \$dir -mindepth 1 -maxdepth 1 \\( $SKIM_DOTFILES_FILTER \\) \
	-o -type d -print 2> /dev/null | skim-csort | awk 'BEGIN {print \"..\"} {print \$0}' | sed 's@^\./@@'"

	set -q SKIM_TMUX_HEIGHT; or set SKIM_TMUX_HEIGHT 80%
	begin
		set -lx SKIM_DEFAULT_OPTIONS "--height $SKIM_TMUX_HEIGHT --reverse $SKIM_DEFAULT_OPTIONS $SKIM_ALT_C_OPTS"
		eval "$SKIM_ALT_C_COMMAND | "(__skimcmd)' --header "'browse directories with enter and mouse. esc when done.'" -m --query "'$skim_query'"' | read -l result

		if [ -n "$result" ]
			cd "$result"
			
			## Remove last token from commandline.
			#commandline -t ""
			
			# move cursor up
			echo -en '\033[1A'
			
			set -g __skim_cd_widget_one_dotfiles_arg "$dotfiles_arg"
			# this prevents nesting (recursion) and makes the prompt notice chdir
			function recurse-skim-cd-widget-one --no-scope-shadowing --on-event fish_prompt
				functions -e recurse-skim-cd-widget-one
				skim-cd-widget-one $__skim_cd_widget_one_dotfiles_arg
			end
			
			commandline --current-buffer --replace ""
			commandline -f repaint
			commandline -f execute
		else
			# move cursor up
			echo -en '\033[1A'
		end
	end

	commandline -f repaint
end
function skim-csort
	LC_ALL=C sort
end
