# Completion for the ppage function (a thin wrapper around 'grasp --pager')
complete -c ppage -d "Use 'grasp' as pager, a 'fzf' TUI for grepping through a stream"
complete -c ppage -k -a '(__fish_complete_path)'
complete -c ppage -s t -l tail -x -d "Change input limit to BYTES"
complete -c ppage -s n -l line-number -d "Add line numbers"
complete -c ppage -s l -l line -x -d "Jump to line N on startup"
complete -c ppage -l syntax -x -d "Force bat syntax highlighting"
complete -c ppage -l search -x -d "Pre-fill the search box with QUERY on startup"
