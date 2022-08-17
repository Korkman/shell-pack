function skim-cdtagdir -d \
	"cd into tagged and history directories"
	set -l skim_cmd (__skimcmd)
	
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
	| $skim_cmd --ansi --no-multi --reverse --height 40% --bind 'esc:cancel' --header 'enter:cd  esc:abort' --prompt "cd tagged / history: " \
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
