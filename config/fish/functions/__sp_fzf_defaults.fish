function __sp_fzf_defaults -S
	argparse e/exact -- $argv
	set fzf_defaults --info inline-right --input-border=line --input-label $argv[1] --height=~80% --reverse \
		"--color=dark hl:bright-yellow:reverse selected-hl:bright-yellow:reverse current-hl:bright-yellow:reverse header:#00ff87" \
		--header $fzf_header
	if set -q _flag_exact
		set -a fzf_defaults "--exact" "--ghost=[fzf query, exact match]"
	else
		set -a fzf_defaults "--ghost=[fzf query, fuzzy match]"
	end
end
