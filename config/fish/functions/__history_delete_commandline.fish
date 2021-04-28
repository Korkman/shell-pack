function __history_delete_commandline \
-d "Delete current commandline"
	set -l deleted_history (commandline --current-buffer)
	if test "$deleted_history" = ""
		echo -ne "\a"
		return
	end
	history delete --exact --case-sensitive "$deleted_history"
	history save
	echo
	echo "Deleted from history: $deleted_history"
	commandline --current-buffer --replace ""
	commandline -f repaint
end
