function __sp_error -a msg -d \
	'Display a slightly styled error message via stderr'
	begin
		echo -n (set_color ff0)(__spt warnsign)(set_color normal)
		echo " $msg"
	end >&2
end
