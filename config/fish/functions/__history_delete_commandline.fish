function __history_delete_commandline \
  -d "Delete current commandline"
	commandline --current-buffer | read -zl deleted_history    # capture newlines
	set -l deleted_history (string collect -- $deleted_history) # remove trailing newline
	
	if test -z "$deleted_history"
		return
	end
	
	__sp_history_delete $deleted_history
	
	# painting is terrible when clearing multiline buffer - borrowing the users keyboard
	function __history_delete_commandline_info -e fish_prompt
		functions -e __history_delete_commandline_info
		__update_glyphs
		echo (set_color red)"$deleted_glyph"(set_color normal)" F8: History item deleted."
	end
	
	commandline --replace " " # a space triggers postexec
	commandline -f execute
	
end
