function quick_search
	if commandline --paging-mode
		commandline -f pager-toggle-search
	else
		__sp_file_recursive $argv
	end
end
