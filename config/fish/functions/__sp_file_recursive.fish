# inspired by skim/fzf key-bindings.fish
function __sp_file_recursive -d \
	"Pick files and folders - recursive search"
	begin
		echo 'tab:select enter:paste f1:query-syntax alt-p:preview'
		echo 'alt-c:chdir alt-l:pager alt-v:vim f3:mcview f4:mcedit'
		echo 's-arrows:navigate alt-s:recurse-symlinks'
	end | __sp_fzf_header

	set -l fzf_binds (printf %s \
	"alt-p:toggle-preview,ctrl-p:toggle-preview,"\
	"alt-c:print(//chdir)+accept,"\
	"alt-s:become(echo //symlinks:{q}),"\
	"f4:execute(fishcall mcedit {}),"\
	"f3:execute(fishcall mcview {}),"\
	"alt-l:execute(cat {} | fishcall __sp_pager),"\
	"ctrl-v:accept,"\
	"alt-v:execute(vi {}),"\
	"shift-up,alt-up:become(echo //up:{q}),"\
	"shift-down,alt-down:become(echo //down:{q}\\n{}),"\
	"shift-left,alt-left:become(echo //prev:{q}),"\
	"shift-right,alt-right:become(echo //next:{q}),"\
	"f1,alt-h:execute(fishcall cheat --fzf-query),"\
	"ctrl-q:abort"
	)
	
	set -l commandline (__skim_parse_commandline)
	set -l dir $commandline[1]
	set -l query $commandline[2]
	set -l original_dir "$PWD"
	set -l paste_absolute_path 'no'
	
	set -l symlinks '-P'
	while true
		set -e result

		# build find arguments
		set -l find_args find
		set -a find_args $symlinks
		set -a find_args $dir -xdev -mindepth 1
		if [ "$argv[1]" = "--dotfiles" ]
			set -a find_args -false
		else
			set -a find_args -path '.*/.*'
		end
		set -a find_args -prune -o
		if $__cap_find_has_xtype
			set -a find_args -xtype f -print -o -xtype d -print -o -type l -print
		else
			set -a find_args -type f -print -o -type d -print -o -type l -print
		end

		# run find -> fzf, capture multi-selection into $result
		__sp_fzf_defaults 'recursive file picker'
		set -l fzf_args fzf $fzf_defaults -m --query "$query" --bind "$fzf_binds" \
			--preview "[ -d {} ] && ls -al {} || grep \"\" -I {} | head -n4000" \
			--preview-window hidden:right:80%
		
		command $find_args 2> /dev/null \
		| sed 's@^\./@@' \
		| command $fzf_args \
		| while read -l r
			set result $result $r
		end

		if string match -q --regex "^//up:(?<new_query>.*)" -- "$result[1]"
			set query "$new_query"
			cd ..
			set paste_absolute_path 'yes'
			echo
			__force_redraw_prompt
			continue
		else if string match -q --regex "^//down:(?<new_query>.*)" -- "$result[1]"
			set query ""
			if ! test -d "$result[2]"
				cd -- (dirname -- "$result[2]")
			else if test -d "$result[2]"
				cd -- "$result[2]"
			end
			set paste_absolute_path 'yes'
			echo
			__force_redraw_prompt
			continue
		else if string match -q --regex "^//prev:(?<new_query>.*)" -- "$result[1]"
			set query "$new_query"
			quick_dir_prev
			echo
			__force_redraw_prompt
			continue
		else if string match -q --regex "^//next:(?<new_query>.*)" -- "$result[1]"
			set query "$new_query"
			quick_dir_next
			echo
			__force_redraw_prompt
			continue
		else if string match -q --regex "^//symlinks:(?<new_query>.*)" -- "$result[1]"
			set query "$new_query"
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