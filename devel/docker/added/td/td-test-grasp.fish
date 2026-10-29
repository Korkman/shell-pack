function td-test-grasp -d \
	"Run a short automated test suite for the grasp and ppage pagers"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td test-grasp"
		echo
		echo "  Checks exit statuses of grasp's help and error paths, grasp as a"
		echo "  recursive command pipeline and grasp / ppage showing multiple files."
		echo "  Returns the number of failed checks (max 125)."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	set -l tmp (__sp_mkuniq --dir td-test-grasp)
	or return 1
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

	# usage: __td_expect_status DESCRIPTION EXPECTED_STATUS COMMAND...
	function __td_expect_status
		set -l desc $argv[1]
		set -l expected $argv[2]
		set -e argv[1..2]
		$argv >/dev/null 2>&1
		__td_check "$desc" $expected $status
	end

	# help and error exit statuses
	__td_expect_status "grasp --help exits 0" 0 grasp --help
	__td_expect_status "grasp rejects --line=0" 2 grasp --line=0
	__td_expect_status "grasp rejects missing file" 2 grasp --file "$tmp/missing"

	# recursive grasp command pipeline
	dd if=/dev/urandom bs=1024 count=64 of="$tmp/input" 2>/dev/null
	grasp cat < "$tmp/input" > "$tmp/output"; and cmp -s "$tmp/input" "$tmp/output"
	__td_check "recursive grasp command pipeline" 0 $status

	# pagers show all files
	printf 'first\n' > "$tmp/first.txt"
	printf 'second\n' > "$tmp/second.txt"
	for pager in grasp ppage
		set -l found 0
		if $pager --quit-if-one-screen "$tmp/first.txt" "$tmp/second.txt" > "$tmp/output" 2>&1; and string match -q '*first*' < "$tmp/output"; and string match -q '*second*' < "$tmp/output"
			set found 1
		end
		__td_check "$pager shows multiple files" 1 $found
	end

	rm -rf "$tmp"
	echo
	echo "$__td_test_total checks, $__td_test_failed failed"
	set -l failed $__td_test_failed
	set -e __td_test_failed __td_test_total
	functions -e __td_check __td_expect_status
	test $failed -gt 125; and set failed 125
	return $failed
end
