function ppage-if-much -d \
	'Print stdin as-is if it fits within $LINES, otherwise page it through ppage, restricted to PPAGE_IF_MUCH_TAIL lines (default: 1000000)'
	# specifically passing to ppage so this pager can safely be used for systemd
	# caveat: line wrap is not detected (maybe possible with `fold`, if it supports ANSI)
	
	test -n "$PPAGE_IF_MUCH_TAIL"
	or set -l PPAGE_IF_MUCH_TAIL 1000000
	
	set -l max_lines 24
	test -z "$LINES"
	or set max_lines $LINES
	set max_lines (math $max_lines - 3)
	
	set -l cnt 0
	set -l must_page 0
	while read -l chunk
		# instant output to shell
		echo "$chunk"
		# secondary output to buffer
		echo "$chunk" >&2
		set cnt (math $cnt + 1)
		if test $cnt -gt $max_lines
			set must_page 1
			break
		end
	end 2>| read -z -l buffered
	
	if test $must_page = 1
		# more input is still pending: hand off the buffered lines plus the rest of stdin to the pager

		# move cursor up over the lines already streamed to the terminal, then erase them
		printf '\033[%dA\033[J' $cnt

		# use a temporary file to dump the head buffer to
		set -l tmp (__sp_mkuniq --xdg-runtime ppage-if-much)
		printf '%s' $buffered > "$tmp"
		# concat buffer and combine with stdin
		cat "$tmp" - | ppage --tail=$PPAGE_IF_MUCH_TAIL
		rm -f "$tmp"
	else
		return 0
	end
end
