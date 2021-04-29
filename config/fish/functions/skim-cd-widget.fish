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
	set -l original_dir "$PWD"
	set -l paste_absolute_path 'no'
	
	set -l skim_binds (printf %s \
	"ctrl-v:execute(echo //paste:{})+accept,"\
	"alt-l:execute(echo //list:{})+accept,"\
	"shift-up:execute(echo //up)+accept,alt-up:execute(echo //up)+accept,"\
	"shift-down:execute(echo //down:{})+accept,alt-down:execute(echo //down:{})+accept,"\
	"shift-left:execute(echo //prev)+accept,alt-left:execute(echo //prev)+accept,"\
	"shift-right:execute(echo //next)+accept,alt-right:execute(echo //next)+accept,"\
	"ctrl-q:abort"
	)
	set -l skim_help 'cd recursive | esc:cancel enter:done c-v:paste s-arrows:navigate alt-l:list'

	set -q SKIM_ALT_C_COMMAND; or set -l SKIM_ALT_C_COMMAND "
	command find -L \$dir -xdev -mindepth 1 \\( $SKIM_DOTFILES_FILTER \\) -prune \
	-o -type d -print 2> /dev/null | sed 's@^\./@@'"

	set -q SKIM_TMUX_HEIGHT; or set SKIM_TMUX_HEIGHT 40%
	while true
		set -lx SKIM_DEFAULT_OPTIONS "--height $SKIM_TMUX_HEIGHT --reverse $SKIM_DEFAULT_OPTIONS $SKIM_ALT_C_OPTS"
		eval "$SKIM_ALT_C_COMMAND | "(__skimcmd)' --header "'$skim_help'" --query "'$skim_query'" --bind "'$skim_binds'"' | read -l result
		
		if [ -n "$result" ]
			if [ "$result" = "//prev" ]
				quick_dir_prev
			else if [ "$result" = "//next" ]
				quick_dir_next
			else if [ "$result" = "//up" ]
				# navigate one up
				cd ..
				set paste_absolute_path 'yes'
			else if string match -q --regex '^//down:' -- "$result"
				# navigate one down
				set result (string replace --regex '^//down:' '' -- "$result")
				if [ -n "$result" ]
					cd "$result"
				end
			else if string match -q --regex '^//paste:' -- "$result"
				# paste result
				set result (string replace --regex '^//paste:' '' -- "$result")
				if [ "$paste_absolute_path" = "yes" ]
					set result (realpath "$result")
				end
				commandline --insert (string escape -- "$result")
				cd "$original_dir"
				break
			else if string match -q --regex '^//list:' -- "$result"
				# list result
				set result (string replace --regex '^//list:' '' -- "$result")
				ll --color=auto "$result" | less
				continue
			else
				# cd to result
				cd "$result"
				break
			end
			
			__force_redraw_prompt
		else
			cd "$original_dir"
			break
		end
	end

	commandline -f repaint
end
