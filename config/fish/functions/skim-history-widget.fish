function skim-history-widget -d "Show command history"
	set -q SKIM_TMUX_HEIGHT; or set SKIM_TMUX_HEIGHT 40%
	__update_glyphs
	begin
		set -lx SKIM_DEFAULT_OPTIONS "--height $SKIM_TMUX_HEIGHT $SKIM_DEFAULT_OPTIONS $SKIM_CTRL_R_OPTS -m"
		set -lx FZF_DEFAULT_OPTS "$SKIM_DEFAULT_OPTIONS"
		set -lx bind (string escape -- 'f8:print()+print(delete)+accept')
		history -z \
		| eval (__skimcmd) --read0 --print0 --bind $bind --exact --tiebreak index \
		--header "'skim history. search for and select past cmd or esc to abort. f8 to delete.'" -q '(commandline)' \
		| while read -zl result; set -a results (string escape -- $result); end
		
		# magic prefix: an empty line (should be impossible in history), followed by delete
		if test "$results[1]" = "''" && test "$results[2]" = "delete"
			for result in $results[3..]
				#echo "$result"
				eval "history delete --exact --case-sensitive -- $result"
			end
			history save
			echo (set_color red)"$deleted_glyph"(set_color normal)" Deleted "(math (count $results) - 2)" history item(s)"
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
		
	end
	commandline -f repaint
end
