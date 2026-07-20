function __sp_osc8_url -a url -a text -d \
	'OSC8 encode URL (and visible text) to show native link in supporting terminals'
	__spt link
	printf "\e]8;;"
	echo -n $url
	printf "\e\\"
	if test -n "$text"
		echo -n $text
	else
		echo -n $url
	end
	printf "\e]8;;\e\\"
	set_color normal
end
