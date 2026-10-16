function , --description "Comma: spawn command once pipe has data"
	test (count $argv) -gt 0; or set argv cat

	# Read exactly 1 byte, held as octal (binary-safe, incl. NUL)
	dd bs=1 count=1 2>/dev/null | od -An -v -to1 | read -l first_byte
	set first_byte (string trim -- $first_byte)
	test -n "$first_byte"; or return 0 # EOF without data: nothing to do, don't spawn

	# Stream the captured byte plus the rest of stdin downstream
	begin
		command printf "\\$first_byte"
		cat
	end | $argv
	return $pipestatus[-1]
end
