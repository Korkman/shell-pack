function __sp_fzf_defaults -S -d \
	"Set default options for fzf in \$fzf_defaults. Pass title as argument."
	argparse e/exact -- $argv
	

	set fzf_defaults --info inline-right --input-border=line --height=~80% --reverse \
		"--color=dark hl:bright-yellow:reverse selected-hl:bright-yellow:reverse current-hl:bright-yellow:reverse header:#00ff87"

	if set -q _flag_exact
		set -a fzf_defaults "--exact" "--ghost=[fzf query, exact match]"
	else
		set -a fzf_defaults "--ghost=[fzf query, fuzzy match]"
	end
	
	if set -q argv[1]
		set -l input_label (__spt fzf_title bold)" $argv[1] "(set_color normal)
		set -a fzf_defaults --input-label "$input_label"
	end
	
	if set -q fzf_header
		set -a fzf_defaults --header "$fzf_header"
	end
	
	# speed up fzf "execute" and "become" actions by using /bin/sh if available, instead of $SHELL
	if command -q /bin/sh
		set -a fzf_defaults "--with-shell=/bin/sh -c"
	end
	
	return 0
end
