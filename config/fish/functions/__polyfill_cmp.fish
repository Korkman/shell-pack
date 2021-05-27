# this is for archlinux docker container
function __polyfill_cmp -d \
	'Polyfills the basic functionality of cmp, for comparing two files'
	if ! command -q cmp
		function cmp
			argparse --min-args=2 --max-args=2 \
				'b/print-bytes' 'i/ignore-initial' 'l/verbose' 'n/bytes' 'help' \
				's/silent' 'quiet' \
				 \
				-- $argv
			or set -l _flag_help yes
			
			if set -q _flag_b || set -q _flag_i || set -q _flag_l || set -q _flag_n || set -q _flag_help
				echo "cmp polyfilled, umimplemented flag / arguments used!"
				return 2
			end
			
			if set -q _flag_quiet
				set _flag_s quiet
			end
			
			set file1 "$argv[1]"
			set file2 "$argv[2]"
			
			set -l file1_exists no
			if [ -f "$file1" ]
				set file1_exists yes
			end
			
			set -l file2_exists no
			if [ -f "$file2" ]
				set file2_exists yes
			end

			if [ "$file1_exists" != "$file2_exists" ]
				return 1
			end
			
			if command -q diff
				if diff "$file1" "$file2" &> /dev/null
					return 0
				else
					return 1
				end
			else if command -q md5sum
				if [ (md5sum "$file1") = (md5sum "$file2") ]
					return 0
				else
					return 1
				end
			else
				echo "cmp polyfilled, but could not find alternative tool to compare files :-("
			end
		end
	end
	function __polyfill_cmp
		return 0
	end
end
