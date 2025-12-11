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
	__sp_caps_find
	$__cap_find_xtype
	and set arg_xtype '-xtype'
	or set -l arg_xtype '-type'
	
	set -l dir '.'
	set -l skim_query ''
	set -l original_dir "$PWD"
	set -l paste_absolute_path 'no'

	set -l skim_binds (printf %s \
	"enter:become(echo //final:{})+accept,"\
	"alt-l:become(echo //list:{})+accept,"\
	"ctrl-v:become(echo //paste:{})+accept,"\
	"shift-left:become(echo //prev)+accept,alt-left:become(echo //prev)+accept,"\
	"shift-right:become(echo //next)+accept,alt-right:become(echo //next)+accept,"\
	"shift-up:become(echo //up)+accept,alt-up:become(echo //up)+accept,"\
	"shift-down:accept,alt-down:accept,"\
	"ctrl-q:abort,"\
	"esc:cancel"
	)
	set -l skim_help "change directory | esc:cancel enter:done c-v:paste s-arrows:navigate alt-l:list"
	
	set -l cmd_find "
	command find \$dir -mindepth 1 -maxdepth 1 \\( $SKIM_DOTFILES_FILTER \\) \
	-o $arg_xtype d -print 2> /dev/null | skim-csort | awk 'BEGIN {print \".\"} {print \$0}' | sed 's@\./@@'"

	set -q SKIM_TMUX_HEIGHT; or set SKIM_TMUX_HEIGHT 80%
	while true
		set -lx SKIM_DEFAULT_OPTIONS "--height $SKIM_TMUX_HEIGHT --reverse $SKIM_DEFAULT_OPTIONS $SKIM_ALT_C_OPTS"
		set -lx FZF_DEFAULT_OPTS "$SKIM_DEFAULT_OPTIONS"
		eval "$cmd_find | "(__skimcmd)' --ansi --header "'$skim_help'" --query "'$skim_query'" --bind "'$skim_binds'"' | read -l result

		if [ -n "$result" ]
			if [ "$result" = "//prev" ]
				quick_dir_prev
				set cd_success $status
			else if [ "$result" = "//next" ]
				quick_dir_next
				set cd_success $status
			else if [ "$result" = "//up" ]
				cd ..
				set cd_success $status
				set paste_absolute_path 'yes'
			else if string match -q --regex '^//paste:' -- "$result"
				set result (string replace --regex '^//paste:' '' -- "$result")
				if [ "$result" = '.' ]
					set result ''
				end
				if [ "$paste_absolute_path" = "yes" ]
					commandline --insert (string escape -- "$PWD/$result")
				else
					commandline --insert (string escape -- "$result")
				end
				#commandline --cursor 9999
				cd -- "$original_dir"
				break
			else if string match -q --regex '^//final:' -- "$result"
				set result (string replace --regex '^//final:' '' -- "$result")
				if [ "$result" != '.' ]
					cd -- "$result"
					# move cursor up
					#echo -en '\033[1A'
					break
				else
					# move cursor up
					#echo -en '\033[1A'
					break
				end
			else if string match -q --regex '^//list:' -- "$result"
				# list result
				set result (string replace --regex '^//list:' '' -- "$result")
				set -l listing "$PWD/$result"
				set -al listing (ls -al --color=auto "$result")
				for litem in $listing; echo $litem; end | less
				set cd_success 0
				continue
			else if string match -q --regex '^//preview:' -- "$result"
				if test "$preview_window" = "hidden"
					set preview_window default
				else
					set preview_window hidden
				end
				set cd_success 0
				continue
			else
				cd -- "$result"
				set cd_success $status
				set paste_absolute_path 'yes'
			end
			if test $cd_success
				set skim_query ""
				
				echo
				__force_redraw_prompt
			else
				#echo "cd failed."
			end
			
		else
			cd -- "$original_dir"
			# move cursor up
			#echo -en '\033[1A'
			break
		end
	end

	commandline -f repaint
end
function skim-csort
	LC_ALL=C sort
end
