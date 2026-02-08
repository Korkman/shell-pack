function __sp_fzf_defaults -S
	argparse e/exact -- $argv
	set -l input_label (__spt fzf_title bold)" $argv[1] "(set_color normal)
	set fzf_defaults --info inline-right --input-border=line --input-label "$input_label" --height=~80% --reverse \
		"--color=dark hl:bright-yellow:reverse selected-hl:bright-yellow:reverse current-hl:bright-yellow:reverse header:#00ff87" \
		--header $fzf_header
	if set -q _flag_exact
		set -a fzf_defaults "--exact" "--ghost=[fzf query, exact match]"
	else
		set -a fzf_defaults "--ghost=[fzf query, fuzzy match]"
	end
end
