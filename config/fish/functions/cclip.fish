function cclip
	argparse 'h/help' 'd/data=' 'f/force' -- $argv
	or return

	set -l size_limit 71680

	if set -q _flag_help
		echo "cclip - copy data to the clipboard via OSC 52

OSC 52 is a terminal escape sequence that instructs the terminal emulator to
place data into the system clipboard. It works over SSH and in tmux without
any extra tooling, as long as the terminal supports it (most modern terminals do,
some require user approval). Up to $size_limit bytes are commonly accepted.

Usage:
  <command> | cclip           read from stdin
  cclip <file>                read from file
  cclip -d/--data=<data>      read argument

Options:
  -f/--force                    raise the size limit to 100 MiB

Examples:
  cclip secret.txt
  cclip -d 'hello world'
  cat secret.txt | cclip
"
		return 0
	end
	
	if set -q _flag_force
		set size_limit 104857600
	end

	if set -q _flag_data
		echo -n $_flag_data | cclip
		return
	else if set -q argv[1]
		set -l file_size (command wc -c < $argv[1])
		if test $file_size -gt $size_limit
			echo -e "cclip: file too large, use --force to override\n(size $file_size bytes, typical terminal limit is $size_limit bytes)" >&2
			return 1
		end
		cat $argv[1] | cclip
		return
	else
		printf "\033]52;c;"
		head -c $size_limit | base64 | tr -d '\n'
		printf "\a"
	end
end
