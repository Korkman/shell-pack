complete -c cdtagdir --no-files -d "(lsdirtags --color=never | cut -d : -f 2-)" -a "(lsdirtags --color=never | sed 's/:/\t/')"
