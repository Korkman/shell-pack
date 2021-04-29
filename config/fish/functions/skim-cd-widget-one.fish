function skim-cd-widget-one -d "Change directory without changing command"
	# NOTE: the behavior is very different from the original skim-cd-widget-one
	# - it does not substitute the last token of the command with the
	#   arrival directory, nor does it search for it
	# - it allows travelling multiple levels up and down
	# - the commandline stays untouched, so you can chdir without ctrl-c

	if [ "$argv[1]" = "--dotfiles" ]
		set dotfiles_arg "--dotfiles"
		skim-dotfiles yes
	else
		set dotfiles_arg ""
		skim-dotfiles no
	end
	
	set -l dir '.'
	set -l skim_query ''

	set -l skim_binds "left:execute(echo //prev)+accept,right:execute(echo //next)+accept,alt-left:execute(echo //prev)+accept,alt-right:execute(echo //next)+accept"

	set -q SKIM_ALT_C_COMMAND; or set -l SKIM_ALT_C_COMMAND "
	command find -L \$dir -mindepth 1 -maxdepth 1 \\( $SKIM_DOTFILES_FILTER \\) \
	-o -type d -print 2> /dev/null | skim-csort | awk 'BEGIN {print \"..\"} {print \$0}' | sed 's@^\./@@'"

	set -q SKIM_TMUX_HEIGHT; or set SKIM_TMUX_HEIGHT 80%
	while true
		set -lx SKIM_DEFAULT_OPTIONS "--height $SKIM_TMUX_HEIGHT --reverse $SKIM_DEFAULT_OPTIONS $SKIM_ALT_C_OPTS"
		eval "$SKIM_ALT_C_COMMAND | "(__skimcmd)' --header "'browse directories with enter and mouse. esc when done. left+right for history back and forward.'" -m --query "'$skim_query'" --bind "'$skim_binds'"' | read -l result

		if [ -n "$result" ]
			if [ "$result" = "//prev" ]
				quick_dir_prev
				set cd_success $status
			else if [ "$result" = "//next" ]
				quick_dir_next
				set cd_success $status
			else
				cd "$result"
				set cd_success $status
			end
			if test $cd_success
				set skim_query ""
				
				# move cursor up
				echo -en '\033[1A'
				# move cursor to pos1
				echo -en '\r'
				# clear line
				echo -en (string repeat -n $COLUMNS ' ')
				# move cursor up
				echo -en '\033[1A'
				# draw prompt
				fish_prompt
				# draw cmdline
				echo -n (commandline)
			else
				#echo "cd failed."
			end
			
		else
			# move cursor up
			echo -en '\033[1A'
			break
		end
	end

	commandline -f repaint
end
function skim-csort
	LC_ALL=C sort
end
