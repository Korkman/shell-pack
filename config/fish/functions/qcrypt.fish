function qcrypt -d \
	"Password protect files or streams with GPG or OpenSSL."
	
	set -l usage "Usage: qcrypt [--decrypt] [--gpg|--openssl] [--terminal] [INFILE [OUTFILE]]"
	
	argparse 'd/decrypt' 't/terminal' 'gpg' 'openssl' 'h/help' -- $argv
	or begin
		echo "$usage" >&2
		return 1
	end
	
	if set -q _flag_help
		echo "$usage"
		return 0
	end
	
	set -l infile "/dev/stdin"
	set -l outfile "/dev/stdout"
	if test (count $argv) -ge 1
		set infile $argv[1]
	else if not set -q _flag_terminal && test -t 0
		# Abort if stdin is a terminal and --terminal is not specified
		echo "Error: STDIN must be connected to a pipe or file. Override with --terminal or pass argument INFILE." >&2
		return 1
	end
	if test (count $argv) -ge 2
		set outfile $argv[2]
	else if not set -q _flag_terminal && test -t 1
		# Abort if stdout is a terminal and --terminal is not specified
		echo "Error: STDOUT must be connected to a pipe or file. Override with --terminal or pass argument OUTFILE." >&2
		return 1
	end
	
	if test "$infile" = "$outfile"
		echo "Error: INFILE and OUTFILE cannot be the same." >&2
		return 1
	end
	
	set -l mode gpg
	if set -q _flag_openssl
		set mode openssl
	end
	if set -q _flag_gpg
		set mode gpg
	end
	
	if test $mode = openssl
		# Abort if openssl is not available
		if not command -q openssl
			echo "Error: openssl command not found." >&2
			return 2
		end
		
		if set -q _flag_decrypt
			# decrypt
			read -lsP "openssl decryption password: " ENCPASS < /dev/tty
			cat "$infile" | openssl enc -d -aes-256-cbc -pbkdf2 -pass "file:"(echo -n "$ENCPASS" | psub --fifo) > "$outfile"
		else
			# encrypt
			read -lsP "openssl encryption password: " ENCPASS < /dev/tty
			cat "$infile" | openssl enc -aes-256-cbc -pbkdf2 -pass "file:"(echo -n "$ENCPASS" | psub --fifo) > "$outfile"
		end
		return
	else
		
		# Abort if gpg is not available
		if not command -q gpg
			echo "Error: gpg command not found." >&2
			return 2
		end
		
		if set -q _flag_decrypt
			# decrypt
			read -lsP "gpg decryption password: " ENCPASS < /dev/tty
			cat "$infile" | gpg -d --quiet --batch --no-symkey-cache --pinentry-mode loopback --passphrase-file (echo -n "$ENCPASS" | psub --fifo) > "$outfile"
		else
			# encrypt
			read -lsP "gpg encryption password: " ENCPASS < /dev/tty
			cat "$infile" | gpg -c --quiet --batch --no-symkey-cache --pinentry-mode loopback --passphrase-file (echo -n "$ENCPASS" | psub --fifo) > "$outfile"
		end
	end
end
