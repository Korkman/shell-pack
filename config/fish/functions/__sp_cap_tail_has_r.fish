function __sp_cap_tail_has_r
	if type -q tail && tail --help &| string match -qr -- '(^|[^-\w])-r([^-\w]|$)'
		set -g __cap_tail_has_r true
		return 0
	else
		set -g __cap_tail_has_r false
		return 1
	end
end