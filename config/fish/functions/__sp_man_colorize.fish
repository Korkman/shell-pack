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
	function turn_off(which) {
		if (which == "bold"   && !bold_open)   return
		if (which == "under"  && !under_open)  return
		if (which == "italic" && !italic_open) return
		out = out reset
		if (which == "bold")   { bold_open   = 0; bold_ansi   = 0 }
		if (which == "under")  { under_open  = 0; under_ansi  = 0 }
		if (which == "italic") { italic_open = 0; italic_ansi = 0 }
		out = out reapply()
	}
	function turn_off_all() {
		if (bold_open || under_open || italic_open) out = out reset
		bold_open = under_open = italic_open = bold_ansi = under_ansi = italic_ansi = 0
	}
	{
		line = $0
		n = length(line)
		out = ""
		# open flags track current state; the "ansi" companions mark styling that came from a
		# real SGR code (stays on until an explicit off-code) vs. overstrike (ends at next plain char)
		bold_open = under_open = italic_open = bold_ansi = under_ansi = italic_ansi = 0
		i = 1
		while (i <= n) {
			c = substr(line, i, 1)
			# overstrike: one or more "\bchar" repeats stacked on the same column (some
			# renderers, e.g. FreeBSD man.cgi, combine bold+underline as "_\bX\bX")
			if (i + 2 <= n && substr(line, i + 1, 1) == "\b") {
				glyphs = c
				k = i + 1
				while (k + 1 <= n && substr(line, k, 1) == "\b") {
					glyphs = glyphs substr(line, k + 1, 1)
					k += 2
				}
				len_g = length(glyphs)
				final_char = substr(glyphs, len_g, 1)
				is_bold = 0
				is_under = 0
				for (gi = 1; gi < len_g; gi++) {
					gc = substr(glyphs, gi, 1)
					if (gc == "_" && final_char != "_") is_under = 1
					else if (gc == final_char) is_bold = 1
				}
				if (!is_bold && !is_under) is_bold = 1
				# some renderers (e.g. FreeBSD man.cgi mdoc subheadings) follow an
				# underline-only overstrike with a bare, un-backspaced repeat of the
				# same char to fake extra emphasis on dumb terminals - absorb it
				absorb_trailing = (is_under && !is_bold \
					&& k <= n \
					&& substr(line, k, 1) == final_char \
					&& !(k + 1 <= n && substr(line, k + 1, 1) == "\b"))
				if (absorb_trailing) k += 1
				if (!is_bold  && bold_open  && !bold_ansi)  turn_off("bold")
				if (!is_under && under_open && !under_ansi) turn_off("under")
				if (is_bold  && !bold_open)  { out = out bold_on;  bold_open  = 1; bold_ansi  = 0 }
				if (is_under && !under_open) { out = out under_on; under_open = 1; under_ansi = 0 }
				out = out final_char
				i = k
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
					} else if (code == "0" || code == "") {
						# always pass the reset through, even if we did not track this styling ourselves
						turn_off_all()
						out = out "\033[" code "m"
					} else {
						if (code == "22" && bold_open)   { turn_off("bold");   i = j + 1; continue }
						if (code == "23" && italic_open) { turn_off("italic"); i = j + 1; continue }
						if (code == "24" && under_open)  { turn_off("under");  i = j + 1; continue }
						out = out "\033[" code "m"
					}
					i = j + 1
					continue
				}
			}
			# plain character: overstrike-originated styling ends here, ansi-originated persists
			if (bold_open   && !bold_ansi)   turn_off("bold")
			if (under_open  && !under_ansi)  turn_off("under")
			if (italic_open && !italic_ansi) turn_off("italic")
			out = out c
			i += 1
		}
		if (bold_open || under_open || italic_open) out = out reset
		print out
	}
	'
end
