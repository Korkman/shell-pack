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

	# "-path \$dir'*/\\.*'" matches hidden files/folders inside $dir but not
	# $dir itself, even if hidden.
	set -q SKIM_CTRL_T_COMMAND; or set -l SKIM_CTRL_T_COMMAND "
		command find -L \$dir -xdev -mindepth 1 \\( $SKIM_DOTFILES_FILTER \\) -prune \
		-o -type f -print \
		-o -type d -print \
		-o -type l -print 2> /dev/null | sed 's@^\./@@'"

	set -q SKIM_TMUX_HEIGHT; or set SKIM_TMUX_HEIGHT 40%
	begin
	#if [ "$__term_muxer" = "screen" ]
	#	set no_mouse "--no-mouse"
	#end
		set -lx SKIM_DEFAULT_OPTIONS "--height $SKIM_TMUX_HEIGHT --reverse $SKIM_DEFAULT_OPTIONS $SKIM_CTRL_T_OPTS"
		eval "$SKIM_CTRL_T_COMMAND | "(__skimcmd)' -m --query "'$skim_query'"' \
	--header "'skim filenames recursive. enter:paste-in-cmdline c-p:preview c-l:less c-v:vim f3:mcview f4:mcedit c-q:exit'" \
	--bind "'ctrl-p:toggle-preview,f4:execute-silent(echo mcedit)+accept,f3:execute-silent(echo mcview)+accept,ctrl-l:execute-silent(echo less)+accept,ctrl-v:execute-silent(echo vi)+accept,ctrl-q:abort'" \
	--preview "'grep \"\" -I {} | head -n4000'" \
	--preview-window "'hidden:right:80%'" \
	--prompt "'Search filenames: '" \
	$no_mouse \
		| while read -l r; set result $result $r; end
	end
	if [ -z "$result" ]
		commandline -f repaint
		return
	else
		# Remove last token from commandline.
		commandline -t ""
	end
	for i in $result
		commandline -it -- (string escape $i)
		commandline -it -- ' '
	end
	commandline -f repaint
end