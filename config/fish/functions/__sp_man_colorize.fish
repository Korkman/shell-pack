function __sp_man_colorize -d \
	'Convert man/groff overstrike sequences and plain bold/underline SGR into colored ANSI, standing in for bat man-page syntax highlighting'

	# reuse fish's own command/param colors, merged with the actual bold/underline attribute
	set -l bold_on (set_color --bold $fish_color_command)
	set -l under_on (set_color --underline $fish_color_param)
	set -l reset (set_color normal)

	awk -v bold_on="$bold_on" -v under_on="$under_on" -v reset="$reset" '
	{
		line = $0
		n = length(line)
		out = ""
		# open flags track current state; the "ansi" companions mark styling that came from a
		# real SGR code (stays on until an explicit off-code) vs. overstrike (ends at next plain char)
		bold_open = 0
		under_open = 0
		bold_ansi = 0
		under_ansi = 0
		i = 1
		while (i <= n) {
			c = substr(line, i, 1)
			# overstrike: char, backspace, char
			if (i + 2 <= n && substr(line, i + 1, 1) == "\b") {
				c2 = substr(line, i + 2, 1)
				if (c == "_" && c2 != "_") {
					if (bold_open && !bold_ansi) { out = out reset; bold_open = 0 }
					if (!under_open) { out = out under_on; under_open = 1; under_ansi = 0 }
					out = out c2
				} else {
					if (under_open && !under_ansi) { out = out reset; under_open = 0 }
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
					} else if (code == "4") {
						if (!under_open) out = out under_on
						under_open = 1; under_ansi = 1
					} else if (code == "22") {
						if (bold_open) {
							out = out reset; bold_open = 0; bold_ansi = 0
							if (under_open) out = out under_on
						}
					} else if (code == "24") {
						if (under_open) {
							out = out reset; under_open = 0; under_ansi = 0
							if (bold_open) out = out bold_on
						}
					} else if (code == "0" || code == "") {
						if (bold_open || under_open) out = out reset
						bold_open = 0; under_open = 0; bold_ansi = 0; under_ansi = 0
					} else {
						out = out "\033[" code "m"
					}
					i = j + 1
					continue
				}
			}
			# plain character: overstrike-originated styling ends here, ansi-originated persists
			if (bold_open && !bold_ansi) { out = out reset; bold_open = 0 }
			if (under_open && !under_ansi) { out = out reset; under_open = 0 }
			out = out c
			i += 1
		}
		if (bold_open || under_open) out = out reset
		print out
	}
	'
end
