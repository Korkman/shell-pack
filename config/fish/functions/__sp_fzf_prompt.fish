function __sp_fzf_prompt
	echo -n (__spt fzf_prompt_bg bg)(__spt fzf_prompt_fg)
	echo -n " $argv[1] "
	echo -n (set_color normal)(__spt fzf_prompt_bg)(__spt right_black_arrow)(set_color normal)" "
end
