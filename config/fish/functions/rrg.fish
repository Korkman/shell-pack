# fast grep using ripgrep, with visual picker for editing and preview
function rrg -d \
"Search a regex pattern recursively in non-binary files with ripgrep."
	
	if [ "$SHLVL" -gt 100 ]
		echo "Shell level too deep. Are you sleeping on the Enter key?"
		return 1
	end
	
	if test "$argv[1]" = "" || test "$argv[1]" = "--help"
		rrg-help
		return 1
	end >&2
	
	set -l extra_opts
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
	
	# strip the current directory from path arguments so results stay relative
	if test "$PWD" != /
		set -l pwd_prefix "$PWD/"
		set -l pwd_prefix_len (string length -- "$pwd_prefix")
		set -l rel_opts
		for arg in $extra_opts
			if test (string sub --length $pwd_prefix_len -- "$arg") = "$pwd_prefix"
				set -a rel_opts (string sub --start (math $pwd_prefix_len + 1) -- "$arg")
			else if test "$arg" = "$PWD"
				set -a rel_opts .
			else
				set -a rel_opts "$arg"
			end
		end
		set extra_opts $rel_opts
	end
	
	if test "$extra_opts" != ""
		# pass extra_opts down to rrg-in-file
		set -x RG_EXTRA $extra_opts
	end
	
	# export query
	set -x query "$query"
	
	set -l rrg_navigation_keys 'p,v,e,h,q,space,+'
	set -l fzf_binds (printf %s \
		'start:hide-input,'\
		'v,alt-v:toggle-preview,'\
		'f3,alt-p,p:execute(nullerror fishcall __sp_pager --line {2} {1}),'\
		'f4,alt-e,e:execute(nullerror fishcall __sp_editor --line {2} {1}),'\
		'f1,alt-h,h:execute(fishcall rrg-help),'\
		'alt-q:abort,'\
		'q:abort,'\
		'f10:abort,'\
		'esc:transform(fishcall __sp_rrg_key escape),'\
		'enter:transform(fishcall __sp_rrg_key enter),'\
		'+:hide-header+show-input+change-prompt(Filter> )+unbind('$rrg_navigation_keys'),'\
		'space:hide-header+show-input+change-prompt(Filter> )+clear-query+unbind('$rrg_navigation_keys'),'\
		'right-click:toggle-preview,'\
		'home:pos(0),end:pos(-1)'\
	)
	

	printf 'h:help enter,p,f3:page e,f4:edit v:preview\nq:quit space:filter +:edit-filter' | __sp_fzf_header
	# without extra options rg searches the current directory
	set -l search_scope '"'"$PWD"'"'
	if set -q extra_opts[1] && test "$extra_opts" != "."
		set search_scope '"'(string join '", "' -- $extra_opts)'"'
	end
	__sp_fzf_defaults
	set -a fzf_defaults \
		--header-border=inline \
		--input-border=none \
		--list-border=none \
		--border=rounded \
		--footer="Rapid Ripgrep \"$query\" in $search_scope" \
    ;
	# this causes display error in microsoft terminal
	#set -x TERM screen-256color
	# mcview caused escape sequence mess at times
	if isatty 1
		# attached to a terminal
		begin
			rg \
				--no-ignore \
				--no-heading \
				--auto-hybrid-regex \
				--one-file-system \
				--line-buffered \
				--color always \
				--colors match:none \
				--colors match:style:intense \
				--colors match:bg:255,127,0 \
				--colors match:fg:0,0,0 \
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
					| rg --line-buffered --text "" 2> /dev/null
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
		# Strip indentation tabs from the match field, replace remaining tabs with a visible arrow,
		# and remove other low control characters while preserving ANSI color sequences.
		# spawning filters as fish subprocesses to get instant results (fish 3.3.1 buffering issue)
		| fishex-replace '^(.*?//(?:\x1b\[[0-9;]*m)*[0-9]+(?:\x1b\[[0-9;]*m)*//)\t+' '$1' \
		| fishex-replace '\t' '→' \
		| fishex-replace '[\x00-\x08\x0B-\x1A\x1C-\x1F]' '' \
		# will buffer all content until stdin closed?
		#| string replace --all --regex '[\x00-\x1A\x1C-\x1F]' '' \
		# sed on macos Monterey does not support escapes in brackets
		#| LC_ALL=C sed -e 's/[\x00-\x1A\x1C-\x1F]//g' \
		| fzf \
			$fzf_defaults \
			--no-multi \
			--no-hscroll \
			--bind "$fzf_binds" \
			--preview 'clear; rrg-in-file --rrg-preview {} -f {1} -l {2} -t -- $query' \
			--preview-window 'wrap:right:80%:~1' \
			--preview-label 'Preview pane - toggle with v or alt-v' \
			--height (math $LINES-1) \
			--delimiter '//' \
			--ansi \
			--layout reverse
		set fzf_status $status
		echo
		
		# interpret status:
		# rg exits with 0 for found, 1 for not found, 2 for error
		# fzf exits with 130 for esc pressed, 0 for selection was made
		if [ $main_rg_status -le 1 ]
			if [ $fzf_status -ne 0 -a $fzf_status -ne 130 ]
				return $fzf_status
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
