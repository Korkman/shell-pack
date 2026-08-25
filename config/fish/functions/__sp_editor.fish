function __sp_editor -d \
	'Invoke the configured editor'

	argparse 'line=' -- $argv
	or return

	set filename $argv[1]

	if set -q VISUAL
		set EDITOR $VISUAL
	end

	if set -q _flag_line
		set line $_flag_line
		# open the file in the default editor with cursor position for supported editors
		switch "$EDITOR"
			# whitelist of editors known to accept "+linenumber"
			case "*mcedit" "*vi" "*vim" "*nano" "fresh"
				"$EDITOR" +$line "$filename"
			case '*'
				"$EDITOR" "$filename"
		end
	else
		"$EDITOR" "$filename"
	end

end
