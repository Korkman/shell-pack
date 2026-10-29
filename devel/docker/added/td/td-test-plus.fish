function td-test-plus -d \
	"Run a short automated test suite for the + (plus) function"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td test-plus"
		echo
		echo "  Checks that + streams while its input is still open, round-trips binary"
		echo "  data (including leading NUL, newline and high bytes), passes arguments on,"
		echo "  falls back to cat without a command, delays spawning until the first byte"
		echo "  arrives, propagates the exit status of its command and does not spawn the"
		echo "  command on empty input. Returns the number of failed checks (max 125)."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	if not command -vq pv
		echo "td test-plus: missing required binary: pv" >&2
		echo "Install with:" >&2
		echo "  apt:  apt install pv" >&2
		echo "  apk:  apk add pv" >&2
		return 1
	end

	set -l tmp (__sp_mkuniq --dir --xdg-runtime td-test-plus)
	or return 1
	pushd "$tmp"; or return 1
	set -g __td_test_failed 0
	set -g __td_test_total 0

	# usage: __td_check DESCRIPTION EXPECTED ACTUAL
	function __td_check
		set -g __td_test_total (math $__td_test_total + 1)
		if test "$argv[2]" = "$argv[3]"
			echo "ok     $argv[1]"
		else
			set -g __td_test_failed (math $__td_test_failed + 1)
			echo "FAILED $argv[1]: expected '$argv[2]', got '$argv[3]'"
		end
	end

	# streams while the producer is still running (the pv example from the issue),
	# a buffering implementation would produce no output before EOF and pv never ends
	timeout 2 pv -q -L 1m /dev/zero | + cat | + pv -q > streamed
	test -s streamed
	__td_check "streams while input is open" 0 $status

	# binary-safe round trip, including leading NUL, newline and high bytes
	head -c 1000000 /dev/urandom > random.bin
	+ cat < random.bin | cmp -s - random.bin
	__td_check "1 MB random data intact" 0 $status
	begin; printf '\0'; head -c 100000 /dev/urandom; end > nul.bin
	+ cat < nul.bin | cmp -s - nul.bin
	__td_check "leading NUL byte intact" 0 $status
	begin; printf '\n'; head -c 100000 /dev/urandom; end > nl.bin
	+ cat < nl.bin | cmp -s - nl.bin
	__td_check "leading newline intact" 0 $status
	printf '\377rest' | + cat > hi.bin
	__td_check "leading high byte intact" "ff 72 65 73 74" (od -An -v -tx1 < hi.bin | string trim | string replace -ra ' +' ' ')

	# arguments are passed on, without a command the input is passed through
	__td_check "command with arguments" ABC (echo abc | + string upper)
	__td_check "no command falls back to cat" noarg (echo noarg | +)

	# exit status of the command is propagated
	printf x | + sh -c 'exit 3'
	__td_check "exit status propagated" 3 $status

	# spawn is delayed until the first byte arrives
	set -l start (date +%s)
	set -l spawn_at (sh -c 'sleep 2; echo x' | + sh -c 'date +%s')
	test (math $spawn_at - $start) -ge 2
	__td_check "spawn waits for data" 0 $status

	# empty input: command is not spawned, and the exit status is 0
	set -l empty_out (printf '' | + echo SHOULD_NOT_RUN)
	__td_check "empty input does not spawn" "" "$empty_out"
	printf '' | + true
	__td_check "empty input returns 0" 0 $status

	popd
	rm -rf "$tmp"
	echo
	echo "$__td_test_total checks, $__td_test_failed failed"
	set -l failed $__td_test_failed
	set -e __td_test_failed __td_test_total
	functions -e __td_check
	test $failed -gt 125; and set failed 125
	return $failed
end
