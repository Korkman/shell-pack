function __sp_cap_man_roff_has_italics
	if ! command -q man
		set -g __cap_man_roff_has_italics false
		return 1
	end

	# trial-and-error: some systems (e.g. Debian bookworm's nroff) don't accept MANROFFOPT='-P-i'
	set -l esc (printf '\033')
	set -l out (printf '.TH TEST 1\n.SH DESCRIPTION\n.I italic\n' | MANROFFOPT='-P-i' MAN_KEEP_FORMATTING=1 PAGER=cat MANPAGER=cat command man -l - 2>/dev/null | string collect)
	
	if string match -q -- "*"$esc"[3m*" $out
		set -g __cap_man_roff_has_italics true
		return 0
	else
		set -g __cap_man_roff_has_italics false
		return 1
	end
end
