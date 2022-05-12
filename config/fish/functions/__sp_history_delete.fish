function __sp_history_delete \
	-d "Delete a history item. Requires escaped string as argument, dealing with newlines!"
	set -l deleted_history $argv[1]
	
	history delete --exact --case-sensitive -- $deleted_history
	history save
end
