function __sp_clean_utf8 -d \
	'Attempt to clean dirty text into utf-8 on a best-effort basis'
	if test (count $argv) -eq 0
		set tmpfile (mktemp /tmp/__sp_clean_utf8.XXXXXX.html)
		cat > $tmpfile
		set input $tmpfile
	else
		set input $argv[1]
	end
	
	set -l cmd
	if command -q iconv
		set cmd iconv -t utf-8 -c
		if command -q file
			set -l detected (file -bi $input | string match -g --regex "charset=([^ ]+)")
			if test $pipestatus[1] -eq 0
				set -a cmd -f $detected
			end
		end
	else
		set cmd cat
	end
	$cmd $input
end
