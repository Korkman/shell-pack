function td-test-all -d \
	"Run all td-test-* modules and report which ones failed"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td test-all"
		echo
		echo "  Runs every td-test-* module in turn, including ones not yet loaded."
		echo "  A module counts as failed when it exits non-zero. Returns the number"
		echo "  of failed modules (max 125)."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	set -l modules (functions -a | string match -- 'td-test-*' | string match -v -- td-test-all | sort)
	if not set -q modules[1]
		echo "td test-all: no td-test-* modules found" >&2
		return 1
	end

	set -l failed_modules
	for module in $modules
		echo "== $module"
		$module
		set -l module_status $status
		if test $module_status -ne 0
			set -a failed_modules "$module (exit $module_status)"
		end
		echo
	end

	echo "td test-all: "(count $modules)" modules, "(count $failed_modules)" failed"
	for failed in $failed_modules
		echo "FAILED $failed"
	end

	set -l failed (count $failed_modules)
	test $failed -gt 125; and set failed 125
	return $failed
end
