# Store current token in $dir as root for the 'find' command
function skim-file-widget -d "List files and folders"
	if [ "$argv[1]" = "--dotfiles" ]
		skim-dotfiles yes
	else
		skim-dotfiles no
	end
	__sp_caps_find
	$__cap_find_xtype
	and set arg_xtype '-xtype'
	or set -l arg_xtype '-type'
	
	set -l commandline (__skim_parse_commandline)
	set -l dir $commandline[1]
	set -l skim_query $commandline[2]
	set -l original_dir "$PWD"
	set -l paste_absolute_path 'no'
	
	set -l skim_binds (printf %s \
	"alt-p:toggle-preview,ctrl-p:toggle-preview,"\
	"alt-c:print(//chdir)+accept,"\
	"alt-s:become(echo //symlinks:{q})+accept,"\
	"f4:execute(mcedit {}),"\
	"f3:execute(mcview {}),"\
	"ctrl-l:execute(less {}),"\
	"ctrl-v:accept,"\
	"alt-v:execute(vi {}),"\
	"shift-up:print(//up)+accept,alt-up:print(//up)+accept,"\
	"shift-down:print(//down)+accept,alt-down:print(//down)+accept,"\
	"shift-left:print(//prev)+accept,alt-left:print(//prev)+accept,"\
	"shift-right:print(//next)+accept,alt-right:print(//next)+accept,"\
	"ctrl-q:abort"
	)
	begin
		echo 'tab:select enter:paste c-v:paste alt-p:preview alt-s:recurse-symlinks c-l:less'
		echo 'alt-v:vim f3:mcview f4:mcedit s-arrows:navigate alt-c:chdir'
	end | read -lz skim_help

	# "-path \$dir'*/\\.*'" matches hidden files/folders inside $dir but not
	# $dir itself, even if hidden.
	set -l cmd_find "
		command find \$symlinks \$dir -xdev -mindepth 1 \\( $SKIM_DOTFILES_FILTER \\) -prune \
		-o $arg_xtype f -print \
		-o $arg_xtype d -print \
		-o -type l -print 2> /dev/null | sed 's@^\./@@'"

	set -q SKIM_TMUX_HEIGHT; or set SKIM_TMUX_HEIGHT 40%
	set -l symlinks '-P'
	while true
		set -e result
		set -lx SKIM_DEFAULT_OPTIONS "--height $SKIM_TMUX_HEIGHT --reverse $SKIM_DEFAULT_OPTIONS $SKIM_CTRL_T_OPTS"
		set -lx FZF_DEFAULT_OPTS "$SKIM_DEFAULT_OPTIONS"
		eval "$cmd_find | "(__skimcmd)' -m --query "'$skim_query'"' \
		--header "'$skim_help'" \
		--bind "'$skim_binds'" \
		--preview "'[ -d {} ] && ls -al {} || grep \"\" -I {} | head -n4000'" \
		--preview-window "'hidden:right:80%'" \
		--prompt "'Filter paths: '" \
		| while read -l r; set result $result $r; end
		
		if [ "$result[1]" = "//up" ]
			cd ..
			set paste_absolute_path 'yes'
			echo
			__force_redraw_prompt
			continue
		else if [ "$result[1]" = "//down" ]
			if test -d "$result[2]"
				cd "$result[2]"
			end
			set paste_absolute_path 'yes'
			echo
			__force_redraw_prompt
			continue
		else if [ "$result[1]" = "//prev" ]
			quick_dir_prev
			echo
			__force_redraw_prompt
			continue
		else if [ "$result[1]" = "//next" ]
			quick_dir_next
			echo
			__force_redraw_prompt
			continue
		else if string match -q --regex "^//symlinks:(?<skim_query>.*)" -- "$result[1]"
			if [ "$symlinks" = '-P' ]
				set symlinks '-L'
			else
				set symlinks '-P'
			end
			continue
		else if [ "$result[1]" = "//chdir" ]
			set -l chdir_dest "$result[2]"
			if [ ! -d "$chdir_dest" ]
				set chdir_dest (dirname "$chdir_dest")
			end
			cd "$chdir_dest"
			commandline -f repaint
			return
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
			commandline -it -- (string escape -- (realpath "$i"))
		else
			commandline -it -- (string escape -- $i)
		end
		commandline -it -- ' '
	end
	cd "$original_dir"
	commandline -f repaint
end