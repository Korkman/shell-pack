# inspired by skim/fzf key-bindings.fish
function __sp_history_search -d \
	"Access and censor command history"
	echo "esc:abort enter:accept f1:query-help f8:delete tab:select" | __sp_fzf_header
	set -l fzf_binds (printf %s \
		'f8:print()+print(delete)+accept,' \
		'f1,alt-h:execute(fishcall cheat --fzf-query)'
	)
	
	__sp_fzf_defaults 'history' --exact
	set -l fzf_args fzf $fzf_defaults --read0 --print0 --bind "$fzf_binds" --tiebreak index --no-sort \
	--query (commandline) -m \
	--height=80% # no tilde, fzf cannot handle multiline elements with it
	
	history -z \
	| command $fzf_args \
	| while read -zl result
		set -a results (string escape -- $result)
	end
	
	# magic prefix: an empty line (should be impossible in history), followed by delete
	if test "$results[1]" = "''" && test "$results[2]" = "delete"
		for result in $results[3..]
			# using eval so deletion of multi-line cmds works
			eval "history delete --exact --case-sensitive -- $result"
		end
		history save
		echo (__spt deleted_fg)(__spt deleted)(set_color normal)" Deleted "(math (count $results) - 2)" history item(s)"
	else
		if test (count $results) -gt 1
			# Triple-space prefix to prevent any special handling and also to not
			# submit combined content to history
			commandline --replace (echo -e "   \n")
			for result in $results
				if test (string length -- $result) -gt 1 && test (string sub --start -2 --length 2 -- $result) = '\n'
					# trailing newline detected, has to be removed here
					set result (string sub --end -2 -- $result)
				end
				
				eval "commandline --append -- $result\\;\\n"
			end
			commandline --cursor 9999
		else if test "$results" != ""
			eval "commandline -- $results[1]"
		end
		
	end
	commandline -f repaint
end
