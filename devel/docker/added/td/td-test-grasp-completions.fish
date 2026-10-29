function td-test-grasp-completions -d \
	"Run a short automated test suite for the grasp and ppage completions"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td test-grasp-completions"
		echo
		echo "  Checks grasp and ppage completions for file names, delegated commands,"
		echo "  options and option values in a temporary directory. Returns the number of"
		echo "  failed checks (max 125)."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	set -l repo (path resolve (dirname (status filename))/../../../..)
	source "$repo/config/fish/completions/grasp.fish"
	source "$repo/config/fish/completions/ppage.fish"

	set -l tmp (__sp_mkuniq --dir --xdg-runtime td-test-grasp-completions)
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

	# usage: __td_expect_completion LINE EXPECTED PRESENCE(yes|no)
	function __td_expect_completion -a line expected presence
		set -l candidates (complete -C "$line" | string replace -r '\t.*$' '')
		set -l found no
		contains -- "$expected" $candidates; and set found yes
		__td_check "complete '$line' offers $expected (present=$presence)" $presence $found
	end

	touch sentinel.txt 'space file.txt'
	or return 1
	mkdir __sp_grasp_completion_directory
	or return 1

	function __sp_grasp_completion_command
	end
	function __sp_grasp_completion_directory
	end
	function '__sp grasp completion'
	end
	for cmd in __sp_grasp_completion_command __sp_grasp_completion_directory '__sp grasp completion'
		complete -c "$cmd" -f
		complete -c "$cmd" -f -l delegated
		complete -c "$cmd" -l choose -x -a chosen-value
	end

	__td_expect_completion 'grasp __sp_grasp_completion_c' __sp_grasp_completion_command yes
	__td_expect_completion 'grasp sent' sentinel.txt yes
	__td_expect_completion 'grasp --cmd sent' sentinel.txt no
	__td_expect_completion 'grasp --file __sp_grasp_completion_c' __sp_grasp_completion_command no
	__td_expect_completion 'grasp --sy' --syntax yes
	__td_expect_completion 'grasp --line ' __sp_grasp_completion_command no
	__td_expect_completion 'grasp --search ' __sp_grasp_completion_command no

	for prefix in grasp ppage 'grasp --cmd' 'grasp --' 'grasp -np' \
		'grasp --search query' 'grasp --search="two words"' 'grasp --prompt prompt' \
		'grasp -l 3' 'grasp -l3' 'grasp --tail' 'grasp --tail=20' 'grasp -t20' \
		'grasp --syntax' 'grasp --syntax=json' 'grasp --no-syntax' 'grasp -F'
		__td_expect_completion "$prefix __sp_grasp_completion_command --del" --delegated yes
	end

	__td_expect_completion 'grasp __sp_grasp_completion_command --choose cho' chosen-value yes
	__td_expect_completion 'grasp __sp_grasp_completion_command --file --del' --delegated yes
	__td_expect_completion 'grasp __sp_grasp_completion_command --sy' --syntax no
	__td_expect_completion 'grasp __sp_grasp_completion_command sent' sentinel.txt no
	__td_expect_completion "grasp '__sp grasp completion' --del" --delegated yes
	__td_expect_completion 'grasp git che' checkout yes
	__td_expect_completion 'grasp string match --reg' --regex yes
	__td_expect_completion 'grasp fish --no-con' --no-config yes
	__td_expect_completion 'grasp --file __sp_grasp_completion_command --del' --delegated no
	__td_expect_completion 'grasp sentinel.txt sent' sentinel.txt yes
	__td_expect_completion "grasp 'space file.txt' sent" sentinel.txt yes
	__td_expect_completion 'grasp __sp_grasp_completion_directory --del' --delegated no
	__td_expect_completion 'grasp --cmd __sp_grasp_completion_directory --del' --delegated yes

	touch __sp_grasp_completion_command
	or return 1
	__td_expect_completion 'grasp __sp_grasp_completion_command --del' --delegated no
	__td_expect_completion 'grasp __sp_grasp_completion_command sent' sentinel.txt yes
	__td_expect_completion 'grasp --cmd __sp_grasp_completion_command --del' --delegated yes
	__td_expect_completion 'grasp --cmd --file __sp_grasp_completion_command --del' --delegated no
	__td_expect_completion 'grasp --file --cmd __sp_grasp_completion_command --del' --delegated no

	for cmd in __sp_grasp_completion_command __sp_grasp_completion_directory '__sp grasp completion'
		complete -c "$cmd" -e
	end
	functions -e __sp_grasp_completion_command __sp_grasp_completion_directory '__sp grasp completion'
	popd
	rm -rf "$tmp"
	echo
	echo "$__td_test_total checks, $__td_test_failed failed"
	set -l failed $__td_test_failed
	set -e __td_test_failed __td_test_total
	functions -e __td_check __td_expect_completion
	test $failed -gt 125; and set failed 125
	return $failed
end
