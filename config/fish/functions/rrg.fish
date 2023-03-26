# fast grep using ripgrep, with visual picker for editing and preview
function rrg -d "Search recursively for a pattern (ripgrep regex) in non-binary files. Pipes unlimited, plain filenames. Displays rich skim frontend on terminal."
	__update_glyphs
	if [ "$SHLVL" -gt 100 ]
		echo "Shell level too deep. Are you sleeping on the Enter key?"
		return 1
	end
	
	set -l extra_opts
	if [ "$argv" != "" ]
		set query "$argv"
		# detect query separator '--' and, if present, load extra arguments passed to rg and split query off
		if contains \-- -- $argv
			set -l pos (contains -i \-- -- $argv)
			if test $pos -gt 1
				set -a extra_opts $argv[1..(math $pos - 1)]
			end
			set query (string join ' ' -- $argv[(math $pos + 1)..])
		else if [ (string sub --start 1 --end 1 -- "$argv") = '-' -a (count $argv) -gt 1 ]
			# no -- present, but it looks like user wanted to add options
			echo 'It looks like you tried to pass options to rg.' >&2
			echo 'rrg requires -- separating query from options in this case.' >&2
			return 5
		end
	else
		echo 'rrg'
		echo
		echo 'Uses ripgrep to search for content. Shows interactive results list.'
		echo 'Will switch to pcre2 when necessary (auto-hybrid-regex).'
		echo
		echo 'Search example with escaped character: \$varname'
		echo 'Example with word boundary match: (\W|^)\$varname(\W|$)'
		echo
		echo 'Short term history works. Try arrow keys.'
		echo 
		read -p 'set_color green; echo -n "Search for (ctrl-c to abort): "; set_color normal' query || exit 1
	end
	if test "$extra_opts" != ""
		# pass extra_opts down to rrg-in-file
		set -x RG_EXTRA $extra_opts
	end
	
	# export query
	set -x query "$query"
	
	set -l skim_cmd (__skimcmd)
	set -l skim_binds (printf %s \
		'ctrl-p:toggle-preview,'\
		'ctrl-v:execute(nullerror vi +{2} {1}),'\
		'f3:execute(nullerror fishcall mcview {1}),'\
		'f4:execute(nullerror fishcall mcedit {1}:{2}),'\
		'ctrl-l:execute(clear; nullerror less +{2}g {1}),'\
		'ctrl-h:execute(fishcall rrg-help),'\
		'ctrl-q:abort,'\
		'f10:abort,'\
		'esc:cancel,'\
		'ctrl-i:change-preview(printf "(press ctrl-p to toggle pane)\nFull line #{n}:\n\n%s" {} | less -R)+change-preview-window(wrap:nohidden:bottom:60%:~1)+refresh-preview,'\
		'ctrl-o:change-preview(clear; rrg-in-file --rrg-preview {} -f {1} -l {2} -t -- $query)+change-preview-window(wrap:nohidden:right:80%:~1)+refresh-preview,'\
		'enter:execute(fishcall rrg-in-file -f {1} -l {2} -- $query),'\
		'right-click:toggle-preview'
	)
	# not fzf compatible
	#	'shift-left:preview-left,shift-right:preview-right'
	
	# this causes display error in microsoft terminal
	#set -x TERM screen-256color
	# mcview caused escape sequence mess at times
	if isatty 1
		# attached to a terminal
		begin
			rg \
				--no-config \
				--no-ignore \
				--no-heading \
				--auto-hybrid-regex \
				--one-file-system \
				--line-buffered \
				--color=always \
				--max-columns 160 \
				--with-filename \
				--ignore-case \
				--hidden \
				--line-number \
				$extra_opts \
				-e "$query" \
				2>| begin
					# format inline errors using awk, output line-buffered with rg (should prevent mixed lines)
					awk '{print "\033[0;31m!\033[0m:ERROR: \033[0;31m" $0 "\033[0m"}' \
					| rg --no-config --line-buffered --text "" 2> /dev/null
				end
				# read spawns fish processes, consumes PIDs = fork bomb detection kills fish
				#while read -l line
				#	# inline error reporting, compatible with rrg-in-file preview
				#	echo (set_color red)"!"(set_color normal)":ERROR: "(set_color red)"$line"(set_color normal)
				#end
				set main_rg_status $pipestatus[1]
			#set main_rg_status $status
		end \
		| head -n 100000 2> /dev/null \
		| $skim_cmd \
			--no-multi \
			--bind "$skim_binds" \
			--preview 'clear; rrg-in-file --rrg-preview {} -f {1} -l {2} -t -- $query' \
			--preview-window 'hidden:wrap:right:80%:~1' \
			--delimiter ':' \
			--header 'ctrl-h:help enter:results-in-file c-p:pane c-l:less c-v:vim f3:mcview f4:mcedit c-i:line c-o:content' \
			--ansi \
			--prompt "Fuzzy search in list: " \
			--layout reverse
		set skim_status $status
		echo
		
		# interpret status:
		# rg exits with 0 for found, 1 for not found, 2 for error
		# skim exits with 130 for esc pressed, 0 for selection was made
		if [ $main_rg_status -le 1 ]
			if [ $skim_status -ne 0 -a $skim_status -ne 130 ]
				return $skim_status
			else
				clear
				return 0
			end
		else
			return $main_rg_status
		end
	else
		# attached to a pipe
		rg \
			--no-config \
			--no-ignore \
			--no-heading \
			--auto-hybrid-regex \
			--one-file-system \
			--line-buffered \
			--color=never \
			--ignore-case \
			--hidden \
			--max-count 1 \
			--files-with-matches \
			$extra_opts \
			-e "$query" \
		;
		return $status
	end
end
