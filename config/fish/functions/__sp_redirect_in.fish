function __sp_redirect_in \
	-d "Parametrized redirection from stdin or file" \
	-a filename

	if test -z "$filename" && not isatty 0
		# no filename passed and non-tty connected to stdin: read from stdin
		set filename "-"
	end
	
	if test "$filename" = "-"
		cat
	else
		cat "$filename"
	end
end
