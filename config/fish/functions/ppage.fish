function ppage -d \
"Use 'grasp' as pager, a 'fzf' TUI for grepping through a stream."
	if test "$argv[1]" = "--help"
		echo "Usage: ppage FILE [ OPTIONS ]"
		echo "   or: cat FILE | ppage [ OPTIONS ]"
		echo
		echo -e (functions -vD (status current-function))[5]
		echo
		echo "Limited to 100 MiB by default (GRASP_PAGER_MAX_SIZE)."
		echo
		echo "Options:"
		echo
		echo "  --tail=[BYTES], -t[BYTES]"
		echo "      Change input limit to BYTES."
		echo
		echo "  --line-number, -n"
		echo "      Add line numbers."
		echo "      When reading from STDIN, use 'alt-l' hotkey instead (works on a snapshot)."
		echo
		echo "  --line=N, -lN"
		echo "      Jump to line N on startup."
		echo
		echo "  --syntax[=LANGUAGE]"
		echo "      Force bat syntax highlighting, ignoring the size threshold and stream-mode skip."
		echo "      Optionally pass LANGUAGE to bat's -l flag (e.g. --syntax=json)."
		echo
		echo "When launched, hit 'alt-b' for a list of keybinds. 'q' quits, '/' opens search."
		return 1
	end >&2
	grasp --pager $argv
end
