function __sp_man_page
	# handle --reset: strip flag, remember it
	set -l do_reset no
	if contains -- --reset $argv
		set do_reset yes
		set argv (string match --invert --entire --regex '^--reset$' -- $argv)
	end

	# if no backup exists, proxy to "man"
	if ! functions -q __sp_man_page_default
		function __sp_man_page_default
			if command -q man
				command man $argv
			else
				# man not intalled
				return 1
			end
		end
	end
	
	set -l man_args_plain no
	set -l man_arg_section
	set -l man_arg_topic
	if ! set -q argv[2] && ! string match -q --regex '^-' -- $argv[1]
		# e.g. "man ls"
		set man_args_plain yes
		set man_arg_topic $argv[1]
	else if ! set -q argv[3] && string match -q --regex '^[0-9]+$' -- $argv[1] && ! string match -q --regex '^-' -- $argv[2]
		# e.g. "man 7 signal"
		set man_args_plain yes
		set man_arg_section $argv[1]
		set man_arg_topic $argv[2]
	end
	
	if test $man_args_plain = no
		# e.g. "man --help" or "man -k keyword"
		# doesn't translate to --help or onman calls
		__sp_man_page_default $argv
		return
	end
	
	if command -q man
		# test if fish's man preset finds the help
		# (this introduces a slight latency, sorry. but it catches alternative 'man' use cases well.)
		if PAGER=cat MANPAGER=cat __sp_man_page_default $argv &> /dev/null
			__sp_man_page_default $argv
			return
		else
			set man_status $status
		end
	else
		__sp_error "No manpages installed"
		set man_status 99
	end
	
	set -l search_cmd $man_arg_topic

	# derive a safe universal-variable name for the persisted preference
	set -l pref_var __sp_man_page_pref_(string replace --all --regex '[^a-zA-Z0-9]' '_' -- $search_cmd)

	# --reset: erase persisted preference and continue normally
	if test $do_reset = yes
		if set -q $pref_var
			set -e $pref_var
			echo >&2 (set_color --bold brwhite)"NOTE:"(set_color normal)" Cleared saved help preference for '$search_cmd'"
		end
	end

	# choose appropriate pager
	if set -q MANPAGER
		set pager $MANPAGER
	else if set -q PAGER
		set pager $PAGER
	else
		set pager ppage
	end
	
	# whitelist of commands to always pass --help to
	# NOTE: theoretically a list of all commands known to support --help could go here
	#       to support systems which lack man pages. attempting to strike some balance.
	set wl_dash_dash_help \
		# shell-pack functions
		venv lsports lsnet cheat dl ssmart create qcrypt oldshell ddool nerdlevel \
		cfc cfd qssh ggit qmount qumount ffingerprints ppage grasp mmux one rrg qchroot \
		cclip \
	;
	
	# allow dynamic whitelist to be added
	if set -q dash_dash_help_for_man
		set -a wl_dash_dash_help $dash_dash_help_for_man
	end

	# whitelist commands known to understand -h (but not --help)
	set wl_dash_h \
	;

	# allow dynamic whitelist to be added
	if set -q dash_h_for_man
		set -a wl_dash_h $dash_h_for_man
	end

	if contains -- $search_cmd $wl_dash_dash_help
		set $pref_var hh
	end

	if contains -- $search_cmd $wl_dash_h
		set $pref_var h
	end
	# apply persisted help-method preference (set by choosing option 6 in the menu)
	if set -q $pref_var
		switch $$pref_var
			case hh
				begin
					echo (set_color --bold brwhite)"NOTE:"(set_color normal)" No man page found, paging '$search_cmd --help' instead"(set_color normal)
					echo ""
					# close STDIN on search_cmd so any interactive input is cancelled
					echo -n | $search_cmd --help 2>&1
				end | $pager
				return
			case h
				begin
					echo (set_color --bold brwhite)"NOTE:"(set_color normal)" No man page found, paging '$search_cmd -h' instead"(set_color normal)
					echo ""
					# close STDIN on search_cmd so any interactive input is cancelled
					echo -n | $search_cmd -h 2>&1
				end | $pager
				return
			case o
				onman $argv
				return
			case t
				onman --txt $argv
				return
			case c
				cheat $search_cmd
				return
		end
	end

	# in case we were summoned in the commandline
	echo >&2
	__sp_error \
		"No man page found for: $search_cmd" \
	;
	echo >&2

	# interactive fallback: offer to try --help or -h when stdin is a tty
	if isatty stdin && isatty stdout
		# for saving the previous choice
		set -l chosen_method
		set -l chosen_method_char
		while true
			echo "Alternatives to "(set_color $fish_color_command)"man "(set_color $fish_color_param)"$search_cmd"(set_color normal)
			if type -q $search_cmd
				echo "  1|h) "(set_color $fish_color_command)"$search_cmd "(set_color $fish_color_param)"--help"(set_color normal)
				echo "  2)   "(set_color $fish_color_command)"$search_cmd "(set_color $fish_color_param)"-h"(set_color normal)
			else
				echo "  "(__spt unavailable_option)"1|h) $search_cmd --help"(set_color normal)(set_color $fish_color_comment)"  # not a valid cmd"(set_color normal)
				echo "  "(__spt unavailable_option)"2)   $search_cmd -h"(set_color normal)(set_color $fish_color_comment)"      # not a valid cmd"(set_color normal)
			end
			echo "  3|o) "(set_color $fish_color_command)"onman "(set_color $fish_color_param)"$argv         "(set_color $fish_color_comment)"# fetch man page from internet (roff if supported)"(set_color normal)
			echo "  4|t) "(set_color $fish_color_command)"onman --txt "(set_color $fish_color_param)"$argv   "(set_color $fish_color_comment)"# fetch man page from internet (plain text)"(set_color normal)
			echo "  5|c) "(set_color $fish_color_command)"cheat "(set_color $fish_color_param)"$search_cmd         "(set_color $fish_color_comment)"# fetch cheat sheet from cheat.sh"(set_color normal)
			if test -n "$chosen_method"
				echo "  6|s) "(set_color $fish_color_command)"always use $chosen_method_char) for this command"(set_color normal)
			end
			echo "  q) quit"
			echo
			set -l onman_urls (onman --urls $argv)
			if test "$onman_urls" != ""
				echo "or visit"
				for url in $onman_urls
					echo "  "(__sp_osc8_url $url)
				end
				echo
			end
			
			read --prompt-str="Choice: " --nchars 1 _sp_choice
			echo

			set -l chosen_var
			set -l chosen_flag
			set chosen_method_char $_sp_choice
			switch $_sp_choice
				case 1 h
					if ! type -q $search_cmd
						__sp_error "Not a valid command: $search_cmd"
						continue
					end
					set chosen_flag --help
					set chosen_var dash_dash_help_for_man
					set chosen_method hh
				case 2
					if ! type -q $search_cmd
						__sp_error "Not a valid command: $search_cmd"
						continue
					end
					set chosen_flag -h
					set chosen_var dash_h_for_man
					set chosen_method h
				case 3 o 
					onman $argv
					set chosen_method o
					continue
				case 4 t 
					onman --txt $argv
					set chosen_method t
					continue
				case 5 c
					cheat $search_cmd
					set chosen_method c
					continue
				case 6 s
					if test -z "$chosen_method"
						__sp_error "Make a choice first before saving"
						continue
					end
					set -U $pref_var $chosen_method
					echo (set_color --bold brwhite)"Saved:"(set_color normal)" will always use '$chosen_method_char' for '$search_cmd' (run 'man --reset $search_cmd' to clear)"
					return
				case '*'
					return 0
			end
			
			# temporarily whitelist and recurse
			set -lx $chosen_var $$chosen_var
			set -a $chosen_var $search_cmd
			echo -n | __sp_man_page $argv
		end
		return
	end
	
	# fool __fish_man_page: there's always a way, if we're not asked to search for cmd-assumedverb
	if ! type -q $search_cmd && string match -q -- "*-*" "$search_cmd"
		return 1
	end
	return 0
end
