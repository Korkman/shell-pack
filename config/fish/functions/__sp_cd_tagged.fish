function __sp_cd_tagged -d \
	"cd into tagged and history directories"
	echo 'enter:cd esc:abort' | __sp_fzf_header
	set -l fzf_binds 'esc:cancel'
	
	__sp_fzf_defaults 'cd tagged directory'
	set -l fzf_args fzf $fzf_defaults --ansi --no-multi \
	--bind "$fzf_binds"
	
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
