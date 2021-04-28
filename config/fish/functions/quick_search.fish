function quick_search
	if commandline --paging-mode
		commandline -f pager-toggle-search
	else
		skim-file-widget $argv
	end
end
