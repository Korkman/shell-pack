function __sp_man_page
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
	else if ! set -q argv[3] && ! string match -q --regex '^-' -- $argv[1] && ! string match -q --regex '^-' -- $argv[2]
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
		begin
			echo (set_color --bold brwhite)"NOTE:"(set_color normal)" No man page found, paging '$search_cmd --help' instead"(set_color normal)
			echo ""
			# close STDIN on search_cmd so any interactive input is cancelled
			echo -n | $search_cmd --help 2>&1
		end | $pager
		return
	end

	if contains -- $search_cmd $wl_dash_h
		begin
			echo (set_color --bold brwhite)"NOTE:"(set_color normal)" No man page found, paging '$search_cmd -h' instead"(set_color normal)
			echo ""
			# close STDIN on search_cmd so any interactive input is cancelled
			echo -n | $search_cmd -h 2>&1
		end | $pager
		return
	end
	# in case we were summoned in the commandline
	echo >&2
	__sp_error \
		"No man page found for: $search_cmd" \
	;
	echo >&2

	# interactive fallback: offer to try --help or -h when stdin is a tty
	if isatty stdin && isatty stdout
		while true
			echo "Alternatives to "(set_color $fish_color_command)"man "(set_color $fish_color_param)"$search_cmd"(set_color normal)
			echo "  1|h) "(set_color $fish_color_command)"$search_cmd "(set_color $fish_color_param)"--help"(set_color normal)
			echo "  2)   "(set_color $fish_color_command)"$search_cmd "(set_color $fish_color_param)"-h"(set_color normal)
			echo "  3|o) "(set_color $fish_color_command)"onman "(set_color $fish_color_param)"$search_cmd   "(set_color $fish_color_comment)"# fetch man page from internet"(set_color normal)
			echo "  4|c) "(set_color $fish_color_command)"cheat "(set_color $fish_color_param)"$search_cmd   "(set_color $fish_color_comment)"# fetch cheat sheet from cheat.sh"(set_color normal)
			echo "  q) quit"
			echo
			set -l onman_urls (onman --urls $argv)
			if test "$onman_urls" != ""
				echo "or visit"
				for line in $onman_urls
					echo "  "(set_color $fish_color_redirection)(set_color $fish_color_valid_path)"$line"(set_color normal)
				end
				echo
			end
			
			read --prompt-str="Choice [1234hoc]: " --nchars 1 _sp_choice
			echo

			set -l chosen_var
			set -l chosen_flag
			
			switch $_sp_choice
				case 1 h
					set chosen_flag --help
					set chosen_var dash_dash_help_for_man
				case 2
					set chosen_flag -h
					set chosen_var dash_h_for_man
				case 3 o 
					onman $argv
					continue
				case 4 c
					cheat $argv
					continue
				case '*'
					return 0
			end
			
			# temporarily whitelist and recurse
			set -lx $chosen_var $$chosen_var
			set -a $chosen_var $search_cmd
			echo -n | __sp_man_page $argv
			
			# offer to persist
			# TODO: is this a good thing? choice is easy to select, whitelist hard to undo ...
			#echo
			#read --prompt-str="Persist '$search_cmd' in \$$chosen_var? [y/N]: " --nchars 1 _sp_persist
			#echo
			#if string match -qi y $_sp_persist
			#	set -U -a $chosen_var $search_cmd
			#	echo (set_color green)"Added '$search_cmd' to \$$chosen_var"(set_color normal)
			#end
		end
		return
	end
	
	# fool fish_man_page: there's always a way
	return 0
end
