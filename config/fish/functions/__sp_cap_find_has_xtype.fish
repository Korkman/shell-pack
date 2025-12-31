function __sp_cap_find_has_xtype
	if command find --help &| string match -q -- '*-xtype*'
		set -g __cap_find_has_xtype true
		return 0
	else
		set -g __cap_find_has_xtype false
		return 1
	end
end
