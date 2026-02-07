function __sp_cd_recursive -d "Change directory (recusrive search)"
	set -l original_dir "$PWD"
	set -l paste_absolute_path 'no'
	
	set -l fzf_query ''
	set -l fzf_binds (printf %s \
	"ctrl-v:become(echo //paste:{})+accept,"\
	"alt-l:become(echo //list:{})+accept,"\
	"alt-s:become(echo //symlinks:{q})+accept,"\
	"shift-up:become(echo //up)+accept,alt-up:become(echo //up)+accept,"\
	"shift-down:become(echo //down:{})+accept,alt-down:become(echo //down:{})+accept,"\
	"shift-left:become(echo //prev)+accept,alt-left:become(echo //prev)+accept,"\
	"shift-right:become(echo //next)+accept,alt-right:become(echo //next)+accept,"\
	"ctrl-q:abort"
	)
	set -l fzf_help 'cd recursive | esc:cancel enter:done c-v:paste s-arrows:navigate alt-l:list alt-s:recurse-symlinks'

	set -l symlinks '-P'
	while true
		# construct find arguments
		set -l find_args find
		set -a find_args $symlinks
		set -a find_args . -xdev -mindepth 1
		if [ "$argv[1]" = "--dotfiles" ]
			set -a find_args -false
		else
			set -a find_args -path '.*/.*'
		end
		set -a find_args -prune -o
		if $__cap_find_has_xtype
			set -a find_args -xtype d
		else
			set -a find_args -type d
		end
		set -a find_args -print
		
		# construct fzf arguments
		set -l fzf_args fzf --header "$fzf_help" --query "$fzf_query" --bind "$fzf_binds" --height 40%
		
		command $find_args 2> /dev/null | sed 's@^\./@@' | command $fzf_args | read -l result
		
		if [ -n "$result" ]
			if [ "$result" = "//prev" ]
				quick_dir_prev
			else if [ "$result" = "//next" ]
				quick_dir_next
			else if [ "$result" = "//up" ]
				# navigate one up
				cd ..
				set paste_absolute_path 'yes'
			else if string match -q --regex "^//symlinks:(?<new_fzf_query>.*)" -- "$result"
				set fzf_query "$new_fzf_query"
				if [ "$symlinks" = '-P' ]
					set symlinks '-L'
				else
					set symlinks '-P'
				end
			else if string match -q --regex '^//down:' -- "$result"
				# navigate one down
				set result (string replace --regex '^//down:' '' -- "$result")
				if [ -n "$result" ]
					cd -- "$result"
				end
			else if string match -q --regex '^//paste:' -- "$result"
				# paste result
				set result (string replace --regex '^//paste:' '' -- "$result")
				if [ "$paste_absolute_path" = "yes" ]
					set result (realpath "$result")
				end
				commandline --insert (string escape -- "$result")
				cd -- "$original_dir"
				break
			else if string match -q --regex '^//list:' -- "$result"
				# list result
				set result (string replace --regex '^//list:' '' -- "$result")
				ll --color=auto "$result" | __sp_pager
				continue
			else
				# cd to result
				cd -- "$result"
				break
			end
			echo
			__force_redraw_prompt
		else
			cd "$original_dir"
			break
		end
	end

	commandline -f repaint
end
