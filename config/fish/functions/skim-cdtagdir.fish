function skim-cdtagdir
	set -l skim_cmd (__skimcmd)
	
	lsdirtags | sort | $skim_cmd --no-multi --reverse --height 40% --header 'enter:cd  ctrl-c:abort' --prompt "Fuzzy search in list: " | read -l result
	if [ -n "$result" ]
		set result (string replace --regex ':.*' '' -- "$result")
		cdtagdir "$result"
	end
	commandline -f repaint
end
