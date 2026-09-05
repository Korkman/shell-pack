# Completion for the cheat function
complete -c cheat -f
complete -c cheat -d "Show glyphs cheatsheet" -a "--glyphs" --no-files
complete -c cheat -d "Show 256-color chart" -a "--colors" --no-files
complete -c cheat -d "Show 256-color chart" -a "--colours" --no-files
complete -c cheat -d "Show color INDEX as RGB/hex" -a "--color=" --no-files
complete -c cheat -d "Show mc cheatsheet" -a "--mc" --no-files
complete -c cheat -d "Show tmux cheatsheet" -a "--tmux" --no-files
complete -c cheat -d "Show fzf query syntax" -a "--fzf-query" --no-files
complete -c cheat -d "Query cheat.sh for TOPIC" -a "--chtsh" --no-files
complete -c cheat -d "Show shell-pack cheatsheet" -a "--shell-pack" --no-files
complete -c cheat -d "Show help" -a "--help" --no-files
