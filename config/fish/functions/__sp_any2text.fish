function __sp_any2text --description "Render arbitrary (possibly binary) content as text using an available CLI converter"
	argparse 'h/help' 'l/lesspipe' 'x/hexdump' -- $argv
	or return 1

	if set -q _flag_help
		echo "__sp_any2text - render arbitrary (possibly binary) content as text

Detects whether the input is binary via 'file'. Text input is passed through
unchanged. Binary input is converted using the first available tool from:
lesspipe, hexdump.

Usage:
  __sp_any2text [options] <file>    render FILE

Options:
  -h/--help         show this help
  -l/--lesspipe     force lesspipe
  -x/--hexdump      force hexdump
"
		return 0
	end

	# Determine forced converter (flag shorthand wins)
	set -l force_converter
	if set -q _flag_lesspipe
		set force_converter lesspipe
	else if set -q _flag_hexdump
		set force_converter hexdump
	end

	if set -q force_converter[1] && not command -q $force_converter
		__sp_error "__sp_any2text: requested converter '$force_converter' not found"
		return 1
	end

	set -l input $argv[1]
	if test -z "$input"
		__sp_error "__sp_any2text: FILE argument required"
		return 1
	else if not test -e "$input"
		__sp_error "__sp_any2text: no such file: $input"
		return 1
	end

	set -l ret 0
	if ! __sp_is_file_binary $input
		# already text, pass through unchanged
		cat $input
	else
		set -l filetype
		set -l fileintro
		begin
			echo -- $input
			echo (set_color --bold brwhite)'Binary file type:'(set_color normal)''
			if command -sq file
				set filetype (file -b -- $input)
				echo $filetype
			else
				echo "Undetermined ('file' not installed)"
			end
		end | fold -w 72 | read -z fileintro
		
		set -l candidates $force_converter
		if test -z "$force_converter"
			set candidates lesspipe
			set -a candidates hexdump
		end

		set -l done 0
		for converter in $candidates
			if not command -sq $converter
				continue
			end
			switch $converter
				case lesspipe
					# grab a few bytes from lesspipe to see if it outputs anything
					lesspipe $input | tail -c 128 | string trim | read -z -l lesspipe_head
					if test "$lesspipe_head" != ""
						echo $fileintro
						echo (set_color --bold brwhite)'Converted with:'(set_color normal)' lesspipe'
						lesspipe $input
					else
						# if not, unsupported file -> next converter
						continue
					end
				case hexdump
					echo $fileintro
					echo (set_color --bold brwhite)'Converted with:'(set_color normal)' hexdump'
					set -l hexdump_cmd hexdump -C
					if $__cap_hexdump_has_color
						set -a hexdump_cmd --color=always
					end
					$hexdump_cmd -- $input
			end
			set done 1
			break
		end

		if test $done -eq 0
			__sp_error "__sp_any2text: no converter available (install lesspipe or hexdump)"
			set ret 1
		end
	end

	return $ret
end
