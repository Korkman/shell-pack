function ppage -d \
"Use 'grasp' as pager, a 'fzf' TUI for grepping through a stream."
	if test "$argv[1]" = "--help"
		echo "Usage: ppage FILE [ OPTIONS ]"
		echo "   or: cat FILE | ppage [ OPTIONS ]"
		echo
		echo -e (functions -vD (status current-function))[5]
		echo
		echo "Limited to 100000 lines by default."
		echo
		echo "Options:"
		echo
		echo "  --tail=[COUNT], -t[COUNT]"
		echo "      Change line limit to COUNT."
		echo
		echo "  --line-number, -n"
		echo "      Add line numbers."
		echo "      When reading from STDIN, use 'alt-l' hotkey instead (works on a snapshot)."
		echo
		echo "When launched, hit 'alt-b' for a list of keybinds. 'q' quits, '/' opens search."
		return 1
	end >&2
	grasp --pager $argv
end
