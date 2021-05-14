# Store current token in $dir as root for the 'find' command
function skim-file-widget -d "List files and folders"
	if [ "$argv[1]" = "--dotfiles" ]
		skim-dotfiles yes
	else
		skim-dotfiles no
	end
	set -l commandline (__skim_parse_commandline)
	set -l dir $commandline[1]
	set -l skim_query $commandline[2]
	set -l original_dir "$PWD"
	set -l paste_absolute_path 'no'

	set -l skim_binds (printf %s \
	"ctrl-p:toggle-preview,"\
	"f4:execute-silent(echo //mcedit)+accept,"\
	"f3:execute-silent(echo //mcview)+accept,"\
	"ctrl-l:execute-silent(echo //less)+accept,"\
	"ctrl-v:accept,"\
	"alt-v:execute-silent(echo //vi)+accept,"\
	"shift-up:execute(echo //up)+accept,alt-up:execute(echo //up)+accept,"\
	"shift-left:execute(echo //prev)+accept,alt-left:execute(echo //prev)+accept,"\
	"shift-right:execute(echo //next)+accept,alt-right:execute(echo //next)+accept,"\
	"ctrl-q:abort"
	)
	set -l skim_help 'search files | tab:select enter:paste c-v:paste c-p:preview c-l:less alt-v:vim f3:mcview f4:mcedit s-arrows:navigate'

	# "-path \$dir'*/\\.*'" matches hidden files/folders inside $dir but not
	# $dir itself, even if hidden.
	set -q SKIM_CTRL_T_COMMAND; or set -l SKIM_CTRL_T_COMMAND "
		command find -L \$dir -xdev -mindepth 1 \\( $SKIM_DOTFILES_FILTER \\) -prune \
		-o -type f -print \
		-o -type d -print \
		-o -type l -print 2> /dev/null | sed 's@^\./@@'"

	set -q SKIM_TMUX_HEIGHT; or set SKIM_TMUX_HEIGHT 40%
	while true
		set -e result
		set -lx SKIM_DEFAULT_OPTIONS "--height $SKIM_TMUX_HEIGHT --reverse $SKIM_DEFAULT_OPTIONS $SKIM_CTRL_T_OPTS"
		set -lx FZF_DEFAULT_OPTS "$SKIM_DEFAULT_OPTIONS"
		eval "$SKIM_CTRL_T_COMMAND | "(__skimcmd)' -m --query "'$skim_query'"' \
		--header "'$skim_help'" \
		--bind "'$skim_binds'" \
		--preview "'grep \"\" -I {} | head -n4000'" \
		--preview-window "'hidden:right:80%'" \
		--prompt "'Search filenames: '" \
		| while read -l r; set result $result $r; end
		
		if [ "$result[1]" = "//mcedit" ]
			mcedit "$result[2]"
			set -e result
			break
		else if [ "$result[1]" = "//mcview" ]
			mcview "$result[2]"
			set -e result
			break
		else if [ "$result[1]" = "//less" ]
			less "$result[2]"
			set -e result
			break
		else if [ "$result[1]" = "//vi" ]
			vi "$result[2]"
			set -e result
			break
		else if [ "$result[1]" = "//up" ]
			cd ..
			set paste_absolute_path 'yes'
			__force_redraw_prompt
			continue
		else if [ "$result[1]" = "//prev" ]
			quick_dir_prev
			__force_redraw_prompt
			continue
		else if [ "$result[1]" = "//next" ]
			quick_dir_next
			__force_redraw_prompt
			continue
		end
		
		break
	end
	
	
	if [ -z "$result" ]
		cd "$original_dir"
		commandline -f repaint
		return
	else
		# Remove last token from commandline.
		commandline -t ""
	end
	
	for i in $result
		if [ "$paste_absolute_path" = "yes" ]
			commandline -it -- (string escape (realpath "$i"))
		else
			commandline -it -- (string escape $i)
		end
		commandline -it -- ' '
	end
	cd "$original_dir"
	commandline -f repaint
end