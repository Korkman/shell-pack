function __sp_man_colorize -d \
	'Convert man/groff overstrike sequences and plain bold/underline/italic SGR into colored ANSI, standing in for bat man-page syntax highlighting'

	# reuse fish's own command/param/comment colors, merged with the actual text attribute
	set -l bold_on (set_color --bold $fish_color_command)
	set -l under_on (set_color --underline $fish_color_param)
	set -l italic_on (set_color --italics $fish_color_comment)
	set -l reset (set_color normal)

	awk -v bold_on="$bold_on" -v under_on="$under_on" -v italic_on="$italic_on" -v reset="$reset" '
	function reapply(   s) {
		s = ""
		if (bold_open) s = s bold_on
		if (italic_open) s = s italic_on
		if (under_open) s = s under_on
		return s
	}
	function turn_off_bold() {
		if (bold_open) {
			out = out reset
			bold_open = 0; bold_ansi = 0
			out = out reapply()
		}
	}
	function turn_off_under() {
		if (under_open) {
			out = out reset
			under_open = 0; under_ansi = 0
			out = out reapply()
		}
	}
	function turn_off_italic() {
		if (italic_open) {
			out = out reset
			italic_open = 0; italic_ansi = 0
			out = out reapply()
		}
	}
	function turn_off_all() {
		if (bold_open || under_open || italic_open) out = out reset
		bold_open = 0; under_open = 0; italic_open = 0
		bold_ansi = 0; under_ansi = 0; italic_ansi = 0
	}
	{
		line = $0
		n = length(line)
		out = ""
		# open flags track current state; the "ansi" companions mark styling that came from a
		# real SGR code (stays on until an explicit off-code) vs. overstrike (ends at next plain char)
		bold_open = 0
		under_open = 0
		italic_open = 0
		bold_ansi = 0
		under_ansi = 0
		italic_ansi = 0
		i = 1
		while (i <= n) {
			c = substr(line, i, 1)
			# overstrike: char, backspace, char
			if (i + 2 <= n && substr(line, i + 1, 1) == "\b") {
				c2 = substr(line, i + 2, 1)
				if (c == "_" && c2 != "_") {
					if (bold_open && !bold_ansi) turn_off_bold()
					if (!under_open) { out = out under_on; under_open = 1; under_ansi = 0 }
					out = out c2
				} else {
					if (under_open && !under_ansi) turn_off_under()
					if (!bold_open) { out = out bold_on; bold_open = 1; bold_ansi = 0 }
					out = out c2
				}
				i += 3
				continue
			}
			# already-ANSI SGR (modern grotty): ESC [ code(s) m
			if (c == "\033" && i + 1 <= n && substr(line, i + 1, 1) == "[") {
				j = i + 2
				code = ""
				while (j <= n && substr(line, j, 1) != "m") {
					code = code substr(line, j, 1)
					j += 1
				}
				if (j <= n) {
					if (code == "1") {
						if (!bold_open) out = out bold_on
						bold_open = 1; bold_ansi = 1
					} else if (code == "3") {
						if (!italic_open) out = out italic_on
						italic_open = 1; italic_ansi = 1
					} else if (code == "4") {
						if (!under_open) out = out under_on
						under_open = 1; under_ansi = 1
					} else if (code == "22") {
						if (bold_open) turn_off_bold(); else out = out "\033[22m"
					} else if (code == "23") {
						if (italic_open) turn_off_italic(); else out = out "\033[23m"
					} else if (code == "24") {
						if (under_open) turn_off_under(); else out = out "\033[24m"
					} else if (code == "0" || code == "") {
						# always pass the reset through, even if we did not track this styling ourselves
						turn_off_all()
						out = out "\033[" code "m"
					} else {
						out = out "\033[" code "m"
					}
					i = j + 1
					continue
				}
			}
			# plain character: overstrike-originated styling ends here, ansi-originated persists
			if (bold_open && !bold_ansi) turn_off_bold()
			if (under_open && !under_ansi) turn_off_under()
			if (italic_open && !italic_ansi) turn_off_italic()
			out = out c
			i += 1
		}
		if (bold_open || under_open || italic_open) out = out reset
		print out
	}
	'
end
