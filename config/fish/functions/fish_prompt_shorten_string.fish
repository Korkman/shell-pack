function fish_prompt_shorten_string --no-scope-shadowing -d "Shorten string to percentage of COLUMNS: string percentage"
	set --local vname $argv[1]
	set --local p $argv[2]
	set --local max (math $COLUMNS / 100 x $p)
	if [ (string length -- "$$vname") -gt $max ]
		set --local llen (math round\($max / 2 - 1.9\))
		set --local rlen (math round\($max / 2 - 0.1\))
		if [ $llen -lt 0 ]
			set llen 0
		end
		if [ $rlen -lt 0 ]
			set rlen 0
		end
		set --local lpart (string sub --start 1 --length $llen -- "$$vname")
		set --local rpart (string sub --start -$rlen -- "$$vname")
		set $vname "$lpart""…""$rpart"
	end
end
