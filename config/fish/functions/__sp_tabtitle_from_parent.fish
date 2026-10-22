function __sp_tabtitle_from_parent -d \
	'Derive tab title from the parent process name'
	set -l ppid (ps -o ppid= -p $fish_pid 2>/dev/null | string trim)
	test -n "$ppid"
	or return
	set -l pname (ps -o comm= -p $ppid 2>/dev/null | string trim)
	set pname (path basename (string replace -r '^-' '' -- "$pname"))
	if test -n "$pname"
		set -g tabtitle $pname
	end
end
