# inspired by skim/fzf key-bindings.fish
function __sp_cd_dive -d \
	"Change directory - dive one level"
	begin
		echo 'esc:cancel enter:done f1:query-syntax'
		echo "c-v:paste s-arrows:navigate alt-l:list"
	end | __sp_fzf_header
	set -l fzf_binds (printf %s \
	"enter:become(echo //final:{})+accept,"\
	"alt-l:become(echo //list:{})+accept,"\
	"ctrl-v:become(echo //paste:{})+accept,"\
	"shift-up,alt-up:become(echo //up)+accept,"\
	"shift-down,alt-down:accept,"\
	"shift-left,alt-left:become(echo //prev)+accept,"\
	"shift-right,alt-right:become(echo //next)+accept,"\
	"ctrl-q:abort,"\
	"f1,alt-h:execute(fishcall cheat --fzf-query),"\
	"esc:cancel"
	)
	
	set -l dir '.'
	set -l fzf_query ''
	set -l original_dir "$PWD"
	set -l paste_absolute_path 'no'
	
	while true
		set -l find_args find $dir -mindepth 1 -maxdepth 1
		if [ "$argv[1]" = "--dotfiles" ]
			set -a find_args -false
		else
			set -a find_args -path '.*/.*'
		end
		if $__cap_find_has_xtype
			set -a find_args -o -xtype d
		else
			set -a find_args -o -type d
		end
		set -a find_args -print
		
		__sp_fzf_defaults 'change directory'
		set -l fzf_args fzf $fzf_defaults --ansi --query "$fzf_query" --bind "$fzf_binds"
		
		command $find_args 2> /dev/null \
		| __sp_csort \
		| awk 'BEGIN {print "."} {print $0}' \
		| sed 's@^\./@@' \
		| command $fzf_args \
		| read -l result
		
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
				for litem in $listing; echo $litem; end | __sp_pager
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
				set fzf_query ""
				
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

function __sp_csort
	LC_ALL=C sort
end
