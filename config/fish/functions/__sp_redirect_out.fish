function __sp_redirect_out \
	-d "Parametrized redirection to stdout or file" \
	-a filename

	if test -z "$filename" && not isatty 1
		# no filename passed and non-tty connected to stdout: send to stdout
		set filename "-"
	end
	
	if test "$filename" = "-"
		cat
	else
		cat > "$filename"
	end
end
