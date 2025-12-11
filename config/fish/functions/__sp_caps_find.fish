function __sp_caps_find
	test "$__sp_caps_find_done" = "v1" && return
	if find --help 2> /dev/null | grep -q xtype
		set -g __cap_find_xtype true
	else
		set -g __cap_find_xtype false
	end
	set -g __sp_caps_find_done v1
end
