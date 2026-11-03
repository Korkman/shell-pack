function __sp_editor -d \
	'Invoke the configured editor'

	argparse 'line=' -- $argv
	or return
	
	set -l filename
	if set -q argv[1]
		set filename $argv[1]
	else if ! isatty stdin
		set filename '-'
	end
	
	# unwrap proxied variables
	if test -n "$TRUE_EDITOR"
		set -gx EDITOR "$TRUE_EDITOR"
		set -e TRUE_EDITOR
	end
	if test -n "$TRUE_VISUAL"
		set -gx VISUAL "$TRUE_VISUAL"
		set -e TRUE_VISUAL
	end
	# discard invalid values
	if test "$EDITOR" = "__sp_mc_editor_proxy"
		set -ge EDITOR
	end
	if test "$VISUAL" = "__sp_mc_editor_proxy"
		set -ge VISUAL
	end
	
	if test -n "$VISUAL"
		set -f EDITOR $VISUAL
	end
	
	# $EDITOR may carry arguments, e.g. "code --wait"
	set -l editor_cmd (string split -n -- ' ' (string trim -- "$EDITOR"))
	if ! type -q -- "$editor_cmd[1]"
		__sp_error "\$EDITOR \"$EDITOR\" not found, attempting fallback"
		set editor_cmd
	end
	if not set -q editor_cmd[1]
		if command -q fresh
			set editor_cmd fresh
		else if command -q mcedit
			set editor_cmd mcedit
		else if command -q vim
			set editor_cmd vim
		else if command -q vi
			set editor_cmd vi
		else if command -q nano
			set editor_cmd nano
		else
			__sp_error "No editor found, please set \$EDITOR to a valid choice"
			return 1
		end
	end
	set -l editor_bin $editor_cmd[1]
	set -l editor_args $editor_cmd[2..-1]
	
	# name tab after editor
	__sp_tabtitle_suggestion (path basename "$editor_bin")
	
	if set -q _flag_line
		set line $_flag_line
		# open the file in the default editor with cursor position for supported editors
		switch "$editor_bin"
			# whitelist of editors known to accept "+linenumber"
			case "*mcedit" "*vi" "*vim" "*nano" "fresh"
				"$editor_bin" $editor_args +$line "$filename"
			case '*'
				"$editor_bin" $editor_args "$filename"
		end
	else
		"$editor_bin" $editor_args "$filename"
	end
	set -l editor_status $status
	
	__sp_tabtitle_suggestion --restore
	return $editor_status
end
