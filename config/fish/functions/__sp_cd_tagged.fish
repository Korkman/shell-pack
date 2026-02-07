function __sp_cd_tagged -d \
	"cd into tagged and history directories"
	set -l fzf_header 'cd tagged directory | enter:cd  esc:abort'
	set -l fzf_binds 'esc:cancel'
	
	set -l fzf_args fzf --ansi --no-multi --reverse --height 40% \
	--bind "$fzf_binds" --header "$fzf_header"
	
	begin
		lsdirtags | sort
		set -l mentioned "$PWD" # dedup list
		for i in $dirnext
			if contains -- "$i" $mentioned; continue; end
			set -a mentioned "$i"
			echo ">:$i"
		end
		for i in $dirprev[-1..1]
			if contains -- "$i" $mentioned; continue; end
			set -a mentioned "$i"
			echo "<:$i"
		end
	end \
	| command $fzf_args \
	| read -l result
	if [ -n "$result" ]
		set dest (string replace --regex '.*?:' '' -- "$result")
		# NOTE: while it is possible to navigate with prevd and nextd, it can be confusing when history is lost due to another cd
		#if string match --quiet --regex '^>' -- "$result" && set idx (contains --index $dest $dirnext[-1..1])
		#	nextd $idx
		#else
		cd -- "$dest"
		#end
	end
	commandline -f repaint
end
