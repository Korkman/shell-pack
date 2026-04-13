function __sp_fzf_defaults -S -d \
	"Set default options for fzf in \$fzf_defaults. Pass title as argument."
	argparse e/exact c/compact -- $argv
	

	set fzf_defaults --info inline-right --input-border=line --height=~80% --reverse \
		"--color=dark hl:bright-yellow:reverse selected-hl:bright-yellow:reverse current-hl:bright-yellow:reverse header:#00ff87 header-label:#ffffff:bold" \
		"--color=selected-fg:#ffff00:bold selected-bg:#333300" \
		"--bind=esc:cancel,ctrl-left:backward-word,ctrl-right:forward-word,ctrl-backspace:backward-kill-word,ctrl-delete:kill-word"

	set -l ghost_add
	if set -q _flag_compact
		set ghost_add "$ghost_add, alt-b for more"
		set -a fzf_defaults --bind "start:hide-header"
	else
		set ghost_add ''
	end
	
	if set -q _flag_exact
		set -a fzf_defaults "--exact" "--ghost=[fzf query, exact match"$ghost_add"]" --color "ghost:#6666cc"
	else
		set -a fzf_defaults "--ghost=[fzf query, fuzzy match"$ghost_add"]" --color "ghost:#777700"
	end
	
	if set -q argv[1]
		set -l input_label (__spt fzf_title bold)" $argv[1] "(set_color normal)
		set -a fzf_defaults --input-label "$input_label"
	end
	
	if set -q fzf_header
		set -a fzf_defaults --header "$fzf_header" --bind "alt-b:toggle-header"
		# if multiple newlines are present in the header, add a border and label to hint the key to hide it
		if string match -q --regex ".*\\n.*" -- "$fzf_header"
			set -a fzf_defaults --header-border=line --header-label=" keybinds [alt-b] "
		end
	end
	
	# speed up fzf "execute" and "become" actions by using /bin/sh if available, instead of $SHELL
	if command -q /bin/sh
		set -a fzf_defaults "--with-shell=/bin/sh -c"
	end
	
	return 0
end
