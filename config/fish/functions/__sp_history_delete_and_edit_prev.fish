function __sp_history_delete_and_edit_prev
	set -l deleted_history
	if test -z (commandline --current-buffer | string collect)
		# empty command line, base edit on history
		history -z | read -z deleted_history    # capture newlines
		set deleted_history (string collect -- $deleted_history) # remove trailing newline
		echo
		echo (__spt deleted_fg)(__spt deleted)(set_color normal)" F4: History item deleted, copied to commandline "
		commandline -- $deleted_history
		commandline -f repaint-mode
	else
		# filled command line, base edit on command line
		commandline --current-buffer | read -z deleted_history    # capture newlines
		set deleted_history (string collect -- $deleted_history) # remove trailing newline	
		
		# this is multiline compatible: display a message, then have fish repaint
		# (NOTE: placing the cursor safely outside the multiline editor seems impossible)
		echo -n \r(__spt deleted_fg)(__spt deleted)(set_color normal)" F4: Current command line deleted from history"
		sleep 1 # sleep for the user to read the message before repaint
		commandline -f repaint-mode
	end
	
	__sp_history_delete $deleted_history
end
