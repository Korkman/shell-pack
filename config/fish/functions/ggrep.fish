# fast grep using ripgrep, with visual picker for editing and preview
function ggrep -d "Search recursively for a pattern (ripgrep regex) in non-binary files. Pipes unlimited, plain filenames. Displays rich skim frontend on terminal."
	__update_glyphs
	if [ "$SHLVL" -gt 10 ]
		echo "Shell level too deep. Are you sleeping on the Enter key?"
		return 1
	end
	
	if [ "$argv" != "" ]
		set query $argv
	else
		echo 'ggrep'
		echo
		echo 'Uses ripgrep to search for content. Shows interactive results list.'
		echo 'Will switch to pcre2 when necessary (auto-hybrid-regex).'
		echo
		echo 'Search example with escaped character: \$varname'
		echo 'Example with word boundary match: (\W|^)\$varname(\W|$)'
		echo
		echo 'Short term history works. Try arrow keys.'
		echo 
		read -p 'set_color green; echo -n "Search for (ctrl-c to abort): "; set_color normal' query
	end
	
	# export query
	set -x query $query
	
	# this causes display error in microsoft terminal
	#set -x TERM screen-256color
	# mcview caused escape sequence mess at times
	if isatty 1
		# attached to a terminal
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
			-e $query \
			2> /dev/null \
		| rg --no-config --line-buffered ":" 2> /dev/null \
		| head -n 100000 2> /dev/null \
		| sk \
			--no-multi \
			--bind \
				'ctrl-p:toggle-preview,'\
				'ctrl-v:execute(nullerror vi +{2} {1}),'\
				'f3:execute(nullerror mcview {1}),'\
				'f4:execute(nullerror mcedit {1}:{2}),'\
				'ctrl-l:execute(clear; nullerror less +{2}g {1}),'\
				'ctrl-h:execute(ggrep-help),'\
				'ctrl-q:abort,'\
				'enter:execute(ggrep-in-file -f {1} -l {2} -- $query),'\
				'shift-left:preview-left,shift-right:preview-right,'\
			--preview \
				'clear; ggrep-in-file -f {1} -l {2} -t -- $query' \
			--preview-window 'hidden:right:80%' \
			--delimiter ':' \
			--header 'ctrl-h:help enter:results-in-file c-p:preview c-l:less c-v:vim f3:mcview f4:mcedit' \
			--ansi \
			--prompt "Fuzzy search in list: " \
			--layout reverse \
		;
		set this_status $status
		echo
		status is-interactive; and commandline -f repaint
		if [ $this_status -ne 0 -a $this_status -ne 130 ]
			return $this_status
		else
			clear
			return 0
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
			-e $query \
		;
		return $status
	end
end
