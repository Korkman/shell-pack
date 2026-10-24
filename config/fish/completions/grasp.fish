# Completion for the grasp function
function __sp_complete_grasp
	set -l action $argv[1]
	set -l tokens (commandline -opc)
	set -l argv $tokens[2..-1]
	# Keep option parsing in sync with grasp, including where command arguments begin.
	argparse --stop-nonopt 'P/prompt=' cmd file F/quit-if-one-screen p/pager 't/tail=?' n/line-number 'l/line=' 'syntax=?' no-syntax 'search=' 'then-search=' 'fzf-callback=' help -- $argv 2>/dev/null
	or return 1

	if test "$action" = options
		not set -q argv[1]
		return $status
	end

	set -l mode both
	if set -q _flag_file
		set mode file
	else if set -q _flag_cmd
		set mode command
	else if set -q argv[1]
		set mode file
		if not test -e "$argv[1]"; and type -q -- "$argv[1]"
			set mode command
		end
	end

	if test "$action" = files
		test "$mode" != command
		return $status
	end

	test "$mode" != file; or return 1
	if set -q argv[1]
		type -q -- "$argv[1]"; or return 1
	end
	set -l subcommand (string join ' ' -- (string escape -- $argv))
	set -l current_token (commandline -ct)
	complete -C "$subcommand $current_token"
end

complete -c grasp -f -d "Pipe live stream or file through 'fzf' for searching and filtering"
complete -c grasp -n '__sp_complete_grasp files' -k -F -a '(__fish_complete_path)'
complete -c grasp -f -a '(__sp_complete_grasp command)'
complete -c grasp -n '__sp_complete_grasp options' -f -s t -l tail -d "Change input line limit"
complete -c grasp -n '__sp_complete_grasp options' -f -s n -l line-number -d "Add line numbers"
complete -c grasp -n '__sp_complete_grasp options' -s l -l line -x -d "Jump to line N on startup"
complete -c grasp -n '__sp_complete_grasp options' -f -s p -l pager -d "Use as pager - implied when invoked as 'ppage'"
complete -c grasp -n '__sp_complete_grasp options' -f -l syntax -d "Force bat syntax highlighting, optionally indicate language"
complete -c grasp -n '__sp_complete_grasp options' -f -l no-syntax -d "Disable bat syntax highlighting"
complete -c grasp -n '__sp_complete_grasp options' -l search -x -d "Pre-fill the search box with QUERY on startup"
complete -c grasp -n '__sp_complete_grasp options' -f -s F -l quit-if-one-screen -d "Output content without pager when it fits one screen"
complete -c grasp -n '__sp_complete_grasp options' -f -l cmd -d "Passed argument is strictly a command"
complete -c grasp -n '__sp_complete_grasp options' -f -l file -d "Passed argument is strictly a file"
