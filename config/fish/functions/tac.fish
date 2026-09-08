function tac -d \
	"tac polyfill when native binary is absent."
	argparse -- $argv
	
	if command -sq tac
		#echo "native" >&2
		# erase self so future calls use native tac
		functions -e tac
		command tac -- $argv
		return
	end
	
	if $__cap_tail_has_r
		#echo "polyfill tail" >&2
		tail -r -- $argv
	else
		#echo "polyfill awk" >&2
		# portable fallback: buffer lines, print in reverse order
		awk -- '{ a[NR] = $0 } END { for (i = NR; i > 0; i--) print a[i] }' $argv
	end
end
