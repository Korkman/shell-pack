function __history_delete_commandline \
-d "Delete current commandline"
	commandline --current-buffer | read -zl deleted_history    # capture newlines
	set deleted_history (string escape -- $deleted_history) # somewhat easier to work on the escaped string
	if test (string length -- $deleted_history) -gt 1 -a (string sub --start -2 --length 2 -- $deleted_history) = '\n'
		# trailing newline detected, has to be removed for history to find
		set deleted_history (string sub --end -2 -- $deleted_history)
	end
	#echo $deleted_history
	#return
	if test "$deleted_history" = ""
		echo -ne "\a"
		return
	end
	eval "history delete --exact --case-sensitive -- $deleted_history"
	history save
	
	# painting is terrible when clearing multiline buffer - borrowing the users keyboard
	function __history_delete_commandline_info -e fish_prompt
		functions -e __history_delete_commandline_info
		__update_glyphs
		echo (set_color red)"$deleted_glyph"(set_color normal)" History item deleted."
	end
	commandline --replace " " # a space triggers postexec
	commandline -f execute
	
end
