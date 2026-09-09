# Completion for the __sp_pager function
complete -c __sp_pager -l line -x -d "Jump to line N on startup"
complete -c __sp_pager -l search -x -d "Pre-fill the search box with QUERY on startup"
complete -c __sp_pager -l prompt -x -d "Set the pager's prompt string"
complete -c __sp_pager -s R -l raw -d "Interpret ANSI color escape sequences"
complete -c __sp_pager -l clear-screen -d "Clear the screen before displaying the file"
complete -c __sp_pager -l syntax -x -d "Force bat syntax highlighting (ppage/grasp only)"
