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
	
	if command -q man
		# test if fish's man preset finds the help
		# (this introduces a slight latency, sorry. but it catches alternative 'man' use cases well.)
		set man_output (PAGER=cat MANPAGER=cat __sp_man_page_default $argv 2>&1 | string collect --no-trim-newlines --allow-empty)
		if test $pipestatus[1] = 0
			__sp_man_page_default $argv
			return
		else
			set man_status $status
		end
	else
		__sp_error "No manpages installed"
		set man_status 99
	end
	
	# exit early when complex args were passed as we have no way to translate them to --help or -h
	if test (count $argv) -gt 1 || string match -q --regex '^-' -- $argv[1]
		echo "$man_output" >&2
		return $man_status
	end
	
	# exit early when command does not exist
	set -l search_cmd $argv[1]
	if ! type -q -- $search_cmd
		__sp_error "No man page found and not an executable or alias: $search_cmd"
		return $man_status
	end
	
	if test "$search_cmd" = "man"
		__sp_error "No man page found and not an executable: $search_cmd"
		return $man_status
	end
	
	# choose appropriate pager
	if set -q MANPAGER
		set pager $MANPAGER
	else if set -q PAGER
		set pager $PAGER
	else
		set pager ppage
	end
	
	# don't want to pass --help to just any command. working with whitelists here.
	
	# whitelist commands known to understand --help
	# NOTE: theoretically a list of all commands known to support --help could go here
	#       to support systems which lack man pages. attempting to strike some balance.
	set wl_dash_dash_help \
		# shell-pack functions
		venv lsports lsnet cheat dl ssmart create qcrypt oldshell ddool nerdlevel \
		cfc cfd qssh ggit qmount qumount ffingerprints ppage grasp mmux one rrg qchroot \
		cclip \
		# basics (portability: BSD utils don't support --help, but they will show usage - ignore the warning) \
		tar cp mv chown chmod awk sed grep \
		# tools
		fzf rg dool wezterm scrcpy kitty code mysql mariadb wdotool \
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
			# close STDIN on search_cmd so any interactive input is cancelled
			echo -n | $search_cmd --help
			# hack: echo this to STDOUT so it appears at the end
			echo "" >&1
			echo (set_color brwhite)"NOTICE:"(set_color normal)" No man page found, paging '$search_cmd --help' instead"(set_color normal) >&1
		end &| $pager
		return
	end

	if contains -- $search_cmd $wl_dash_h
		begin
			# close STDIN on search_cmd so any interactive input is cancelled
			echo -n | $search_cmd -h
			# hack: echo this to STDOUT so it appears at the end
			echo "" >&1
			echo (set_color brwhite)"NOTICE:"(set_color normal)" No man page found, paging '$search_cmd -h' instead"(set_color normal) >&1
		end &| $pager
		return
	end
	__sp_error \
		"No man page found and not whitelisted to support --help or -h: $search_cmd" \
	;

	# interactive fallback: offer to try --help or -h when stdin is a tty
	if isatty stdin && isatty stdout
		echo
		echo "Try which flag?"
		echo "  1) --help"
		echo "  2) -h"
		echo "  q) quit"
		echo
		read --prompt-str="Choice [1/2/q]: " --nchars 1 _sp_choice
		echo

		set -l chosen_var
		set -l chosen_flag
		
		switch $_sp_choice
		case 1
			set chosen_flag --help
			set chosen_var dash_dash_help_for_man
		case 2
			set chosen_flag -h
			set chosen_var dash_h_for_man
		case '*'
			return $man_status
		end

		# temporarily whitelist and recurse
		set -lx $chosen_var $$chosen_var
		set -a $chosen_var $search_cmd
		__sp_man_page $argv
		
		# offer to persist
		echo
		read --prompt-str="Persist '$search_cmd' in \$$chosen_var? [y/N]: " --nchars 1 _sp_persist
		echo
		if string match -qi y $_sp_persist
			set -U -a $chosen_var $search_cmd
			echo (set_color green)"Added '$search_cmd' to \$$chosen_var"(set_color normal)
		end
		return
	end
	
	# no whitelist matched, return original man status
	return $man_status
end
