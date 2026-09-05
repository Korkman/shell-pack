# portable mktemp wrapper
# - uses only mktemp -p and -d flags
# - creates directories if necessary
#
# usage examples:
#  me blah -> blah.XXXXXX
#  me --xdg-runtime blah.XXXXXX -> /run/user/1000/blah.XXXXXX
#  me --dir blah -> blah.XXXXXX/
#  me --global-tmp blah -> /tmp/blah.XXXXXX
#  me --dir --global-tmp blah /tmp/blah.XXXXXX/
#  me /run/blah -> /run/blah.XXXXXX
# 
# ALWAYS let the template end with XXXXXX

function __sp_mkuniq -d \
	"Create temporary file or directory"
	argparse 'd/dir' 'g/global-tmp' 'r/xdg-runtime' 'u/dry-run' -- $argv
	or return 1
	
	set -l tpl
	if set -q argv[1]
		set tpl $argv[1]
	else
		set tpl "shell-pack-temp"
	end
	
	if set -q _flag_global_tmp
		set tpl (__sp_path --global-tmp)"/$tpl"
	else if set -q _flag_xdg_runtime
		set tpl (__sp_path --xdg-runtime)"/$tpl"
	end
	
	# start command composition
	set -l cmd mktemp
	
	# split off directory portion, make sure it exists
	set -l tpldir
	if string match -q "*/*" -- $tpl
		set tpldir (string replace --regex -- '/[^/]+$' '' $tpl)
		set tpl (string replace --regex -- '.*/' '' $tpl)
		if ! test -d "$tpldir" && ! set -q _flag_dry_run
			mkdir -p "$tpldir"
		end
		# always set permissions so pre-existing directory is not used as-is
		chmod 0700 "$tpldir"
		set -a cmd -p "$tpldir"
	end
	
	# add XXXXXX suffix if not present
	if ! string match -q -- '*XXXXXX' $tpl
		set tpl "$tpl.XXXXXX"
	end
	
	# advice mktemp to create a directory if requested
	if set -q _flag_dir
		set -a cmd -d
	end
	
	# pass dry-run to mktemp
	if set -q _flag_dry_run
		set -a cmd -u
	end
	
	# append filename template and run
	set -a cmd $tpl
	$cmd
end
