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
		read -p 'set_color green; echo -n "Search for (ctrl-c to abort): "; set_color normal' query || return 1
	end
	if test "$extra_opts" != ""
		# pass extra_opts down to rrg-in-file
		set -x RG_EXTRA $extra_opts
	end
	
	# export query
	set -x query "$query"
	
	set -l fzf_binds (printf %s \
		'alt-p:toggle-preview,'\
		'alt-v:execute(nullerror vi +{2} {1}),'\
		'f3:execute(nullerror fishcall mcview {1}),'\
		'f4:execute(nullerror fishcall mcedit {1}:{2}),'\
		'alt-l:execute(clear; nullerror less +{2}g {1}),'\
		'alt-h:execute(fishcall rrg-help),'\
		'alt-q:abort,'\
		'f10:abort,'\
		'esc:cancel,'\
		'alt-i:change-preview(printf "Result line #{n}:\nLine %s in file %s\nMatched content:\n%s" {2} {1} {3..})+change-preview-window(wrap:nohidden:bottom:60%:~1)+refresh-preview,'\
		'alt-o:change-preview(rrg-in-file --rrg-preview {} -f {1} -l {2} -t -- $query)+change-preview-window(wrap:nohidden:right:80%:~1)+refresh-preview,'\
		'enter:execute(fishcall rrg-in-file -f {1} -l {2} -- $query),'\
		'right-click:toggle-preview,'\
		'home:pos(0),end:pos(-1)'\
	)
	
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
				--color always \
				--max-columns 500 \
				--with-filename \
				--ignore-case \
				--hidden \
				--line-number \
				# things get ugly. only NUL and / are disallowed in linux filenames.
				# fzf cannot split fields on NUL. the only option left is to use two slashes
				# because a single slash can occur in paths.
				--field-match-separator '//' \
				$extra_opts \
				-e "$query" \
				2>| begin
					# format inline errors using awk, output line-buffered with rg (should prevent mixed lines)
					awk '{print "\033[0;31m!\033[0m//ERROR// \033[0;31m" $0 "\033[0m"}' \
					| rg --no-config --line-buffered --text "" 2> /dev/null
				end
				# read spawns fish processes, consumes PIDs = fork bomb detection kills fish
				#while read -l line
				#	# inline error reporting, compatible with rrg-in-file preview
				#	echo (set_color red)"!"(set_color normal)"//ERROR// "(set_color red)"$line"(set_color normal)
				#end
				set main_rg_status $pipestatus[1]
			#set main_rg_status $status
		end \
		| head -n 100000 2> /dev/null \
		# remove all low unprintable ASCII characters from match field (they cannot occur in UTF8, too)
		# with the notable exception of ESC so control sequences (colors!) survive.
		# currently, the one bad character really is the NUL byte which if passed through,
		# sabotages the ability to pass the line from fzf as argument to other tools down the line.
		# fzf sanitizes control sequences, so we (thankfully) don't have to deal with them here.
		# spawning filter as a fish subprocess to get instant results (fish 3.3.1 buffering issue)
		| fishex-replace '[\x00-\x1A\x1C-\x1F]' '' \
		# will buffer all content until stdin closed?
		#| string replace --all --regex '[\x00-\x1A\x1C-\x1F]' '' \
		# sed on macos Monterey does not support escapes in brackets
		#| LC_ALL=C sed -e 's/[\x00-\x1A\x1C-\x1F]//g' \
		| safe-fzf \
			--no-multi \
			--bind "$fzf_binds" \
			--preview 'clear; rrg-in-file --rrg-preview {} -f {1} -l {2} -t -- $query' \
			--preview-window 'hidden:wrap:right:80%:~1' \
			--preview-label 'Preview pane - toggle with ctrl-p' \
			--border top \
			--border-label 'Rapid Ripgrep' \
			--border-label-pos 3 \
			--height (math $LINES-1) \
			--delimiter '//' \
			--header 'alt-h:help enter:results-in-file a-p:pane a-l:less a-v:vim f3:mcview f4:mcedit a-i:line a-o:content' \
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
