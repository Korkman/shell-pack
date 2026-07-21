function __sp_man_page
	# handle --reconfigure: strip flag, remember it
	set -l do_reconfigure no
	if contains -- --reconfigure $argv
		set do_reconfigure yes
		set argv (string match --invert --entire --regex '^--reconfigure$' -- $argv)
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
	if set -q argv[1]
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
	end
	
	if test $man_args_plain = no
		# e.g. "man --help" or "man -k keyword" or just "man"
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

	set -l _persisted_method
	if contains -- $search_cmd $wl_dash_dash_help
		set _persisted_method hh
	end

	if contains -- $search_cmd $wl_dash_h
		set _persisted_method h
	end

	# apply persisted help-method preference (one universal list var per method)
	for _method in hh h o t c
		set -l _var __sp_man_page_saved_$_method
		if set -q $_var && contains -- $search_cmd $$_var
			set _persisted_method $_method
			break
		end
	end
	
	# --reconfigure: remove command from whichever persisted-preference list it appears in
	if test $do_reconfigure = yes
		set -l _cleared no
		for _method in hh h o t c
			set -l _var __sp_man_page_saved_$_method
			if set -q $_var && contains -- $search_cmd $$_var
				set -U $_var (string match --invert --entire --regex '^'(string escape --style=regex -- $search_cmd)'$' -- $$_var)
				set _cleared yes
			end
		end
		if test $_cleared = yes
			echo >&2 (set_color --bold brwhite)"NOTE:"(set_color normal)" Cleared saved help preference for '$search_cmd'"
		end
		set _persisted_method
	end
	
	set -l _sp_choice
	if test -n "$_persisted_method"
		switch $_persisted_method
			case hh
				set _sp_choice h
			case h
				set _sp_choice 2
			case o
				set _sp_choice o
			case t
				set _sp_choice t
			case c
				set _sp_choice c
		end
	end

	# in case we were summoned in the commandline
	echo >&2
	__sp_error \
		"No man page found for: $search_cmd" \
	;
	echo >&2

	set -l chosen_method
	set -l chosen_method_char
	set -l interactive_mode no
	if isatty stdin && isatty stdout && test -z $_persisted_method
		set interactive_mode yes
	end
	
	while true
		if test $interactive_mode = yes
			# interactive mode
			# for saving the previous choice
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
				echo "  6|s) "(set_color normal)"Save"(set_color normal)" option $chosen_method_char) for "(set_color $fish_color_command)"man "(set_color $fish_color_param)"$argv"(set_color normal)(set_color $fish_color_comment)"  # reset with 'man --reconfigure $argv'"(set_color normal)
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
		end
		switch $_sp_choice
			case 1 h
				if ! type -q $search_cmd
					__sp_error "Not a valid command: $search_cmd"
					test $interactive_mode = yes; and continue; or return 1
				end
				begin
					echo (set_color --bold brwhite)"NOTE:"(set_color normal)" Showing '$search_cmd --help'"(set_color normal)
					echo ""
					# close STDIN on search_cmd so any interactive input is cancelled
					echo -n | $search_cmd --help 2>&1
				end | $pager
				set -l cmd_status $status
				set chosen_method hh
				set chosen_method_char $_sp_choice
				test $interactive_mode = yes; and continue; or return $cmd_status
			case 2
				if ! type -q $search_cmd
					__sp_error "Not a valid command: $search_cmd"
					continue
				end
				begin
					echo (set_color --bold brwhite)"NOTE:"(set_color normal)" Showing '$search_cmd -h'"(set_color normal)
					echo ""
					# close STDIN on search_cmd so any interactive input is cancelled
					echo -n | $search_cmd -h 2>&1
				end | $pager
				set -l cmd_status $status
				set chosen_method h
				set chosen_method_char $_sp_choice
				test $interactive_mode = yes; and continue; or return $cmd_status
			case 3 o 
				onman $argv
				set -l cmd_status $status
				set chosen_method o
				set chosen_method_char $_sp_choice
				test $interactive_mode = yes; and continue; or return $cmd_status
			case 4 t 
				onman --txt $argv
				set -l cmd_status $status
				set chosen_method t
				set chosen_method_char $_sp_choice
				test $interactive_mode = yes; and continue; or return $cmd_status
			case 5 c
				cheat $search_cmd
				set -l cmd_status $status
				set chosen_method c
				set chosen_method_char $_sp_choice
				test $interactive_mode = yes; and continue; or return $cmd_status
			case 6 s
				if test -z "$chosen_method"
					__sp_error "Attempt to persist without making a choice first"
					return 2
				end
				
				# remove from any other method list first
				for _method in hh h o t c
					set -l _var __sp_man_page_saved_$_method
					if set -q $_var && contains -- $search_cmd $$_var
						set -U $_var (string match --invert --entire --regex '^'(string escape --style=regex -- $search_cmd)'$' -- $$_var)
					end
				end
				set -Ua __sp_man_page_saved_$chosen_method $search_cmd
				echo (set_color --bold brwhite)"Saved:"(set_color normal)" will always use '$chosen_method_char' for '$search_cmd' (run 'man --reconfigure $search_cmd' to clear)"
				return
			case '*'
				break
		end
		
		return 99
	end

	
	# fool __fish_man_page: there's always a way, if we're not asked to search for cmd-assumedverb
	if ! type -q $search_cmd && string match -q -- "*-*" "$search_cmd"
		return 1
	end
	return 0
end
