# Completion for the grasp function
complete -c grasp -d "Pipe live stream or file through 'fzf' for searching and filtering"
complete -c grasp -k -a '(__fish_complete_path)'
complete -c grasp -s t -l tail -x -d "Change line limit to COUNT (byte limit in --pager mode)"
complete -c grasp -s n -l line-number -d "Add line numbers"
complete -c grasp -s l -l line -x -d "Jump to line N on startup"
complete -c grasp -s p -l pager -d "Use as pager"
complete -c grasp -l syntax -x -d "Force bat syntax highlighting"
complete -c grasp -l search -x -d "Pre-fill the search box with QUERY on startup"
