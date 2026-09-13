# source fish's own excellent man completions
if status get-file completions/man.fish >/dev/null 2>&1
	status get-file completions/man.fish | source
# Fall back to the physical file (Fish 3.x C++ binary)
else if test -f $__fish_data_dir/completions/man.fish
	source $__fish_data_dir/completions/man.fish
end

complete -c man -a '--reconfigure' -d 'Reset saved choice of retrieval when page is missing locally'
complete -c man -a '--line-number' -d 'Add line numbers'
