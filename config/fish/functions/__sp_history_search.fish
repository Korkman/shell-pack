# inspired by skim/fzf key-bindings.fish
function __sp_history_search -d \
	"Access and censor command history"
	set -l fzf_header "search history | search for and select past cmd or esc to abort. f8 to delete."
	set -l fzf_binds 'f8:print()+print(delete)+accept'
	
	set -l fzf_args fzf --read0 --print0 --bind "$fzf_binds" --exact --tiebreak index \
	--header "$fzf_header" \
	--query (commandline) --height 40% -m
	
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
		else
			eval "commandline -- $results[1]"
		end
		
	end
	commandline -f repaint
end
