function __sp_man_page
	# if no backup exists, proxy to "man"
	if ! functions -q __sp_man_page_default
		function __sp_man_page_default
			man $argv
		end
	end
	
	# test if fish's man preset finds the help (this introduces a slight latency, sorry)
	if PAGER=cat MANPAGER=cat __sp_man_page_default $argv > /dev/null 2>&1
		__sp_man_page_default $argv
		return
	else
		set man_status $status
	end
	
	# exit early when command does not exist
	set -l search_cmd $argv[1]
	if ! type -q $search_cmd
		echo "No man page found and not an executable or alias: $search_cmd"
		printf \a
		return $man_status
	end >&2
	
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
		cfc cfd qssh ggit qmount qumount ffingerprints ppage grasp \
		# basics (portability: BSD utils don't support --help, but they will show usage - ignore the warning) \
		tar cp mv chown chmod awk sed grep \
		# tools
		fzf rg dool wezterm scrcpy kitty code mysql mariadb \
	;
	
	# allow dynamic whitelist to be added
	if set -q dash_dash_help_for_man
		set -a wl_dash_dash_help $dash_dash_help_for_man
	end
	
	if contains -- $search_cmd $wl_dash_dash_help
		begin
			$search_cmd --help
			echo "" >&1
			echo (set_color brwhite)"NOTICE:"(set_color normal)" No man page found, paging '$search_cmd --help' instead"(set_color normal) >&1
		end &| $pager
		return
	end
	
	begin
		echo "No man page and not whitelisted to support --help: $search_cmd"
		echo 
		echo "If desired, add with:"
		echo "  set -U -a dash_dash_help_for_man $search_cmd"
	end >&2
	
	# no whitelist matched, return original man status
	printf \a
	return $man_status
end
