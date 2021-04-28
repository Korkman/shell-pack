__polyfill_flock

function qssh -d \
	'Powerful SSH connection and history manager'
	# ~Pierre Beck 2020
	
	# non-standard dependencies:
	# - requires "fish" (tested with 3.1.2)
	# - requires skim ("sk")
	# standard dependencies:
	# - requires openssh ("ssh", "ssh-keygen", "ssh-copy-id")
	# - requires netcat ("nc")
	# - requires "getent"
	# optional dependencies:
	# - midnight commander (mc)
	# - tmux
	
	# TODO: move mru and stuff to .config/qssh
	# TODO: create override option for the globals, like .config/qssh/config
	# TODO: F2 custom commands from .config/qssh/custom_commands
	# TODO: ctrl-c not working while waiting for port connectivity?
	# TODO: System-wide HostKeyChecks cannot be skipped, disable them when in qssh?
	# TODO: ip46: filter/test -1 -2 for SSH protocol versions
	# TODO: store fingerprints & display in preview pane (if pipable on system)
	# TODO: watch fish issue #6649 (open as of 3.1.2), capture SIGINT instead of subprocessing
	# TODO: watch fish issue #6987 (open as of 3.1.2), simplify completions when fixed
	# TODO: add support for *:qssh strings to cli multipick? and / or make multipick items work with args
	# TODO: jumphost support: control connections? unsupported in ssh?
	# TODO: jumphost support: default user does not apply to jumphost
	# TODO: jumphost support: ssh URI scheme
	
	# NOTE: background job spamming own pid - seems fixed in fish 3.1.2
	
	if [ ! -d "~/.ssh" ]
		mkdir ~/.ssh
	end
	
	set -x __qssh_tmp_host_file ~/.ssh/temporary_known_hosts
	set -x __qssh_db_mru_file ~/.ssh/qssh_mru.list
	set -x __qssh_db_autocomplete_cache_file ~/.ssh/qssh_autocomplete.list
	set -x __qssh_db_skim_cache_file ~/.ssh/qssh_skim.list
	set -x __qssh_interval_compact_db 200
	set -x __qssh_controlpath_prefix "~/.ssh/qssh-cp-"
	set -x __qssh_default_user "root" # instead of $USER
	set -x __qssh_prompt_answer_tmp ~/.ssh/qssh-answer.tmp
	set -x __qssh_mru_pick_control_persist_checks 0
	
	# this is for temporary connections
	set -x __qssh_disable_history no
	
	if [ "$argv" != "" ]
	
		if contains -- --qssh-no-history $argv
			set -x __qssh_disable_history yes
			set -e argv[(contains --index -- --qssh-no-history $argv)]
		end
		
		if contains -- --qssh-multipick $argv
			set -e argv[(contains --index -- --qssh-multipick $argv)]
			set -x __qssh_multipick_cli_argv $argv
			__qssh_multipick
			return	
		end
		
		# expand :qssh suffixed string
		# for autocomplete functionality and multipick from cli,
		# hostdefs must be stuffed into an escaped string. this string is
		# expanded here
		if string match -q -- '*:qssh*' $argv
			# keep order and do not mess up $i when expanding! new_argv
			set -l new_argv
			for i in (seq 1 (count $argv))
				if string match -q -- '*:qssh*' $argv[$i]
					set argv[$i] (string replace --regex -- ':qssh$' '' $argv[$i] )
					echo $argv[$i] | read --local --tokenize --list tokenized
					set -a new_argv $tokenized
				else
					set -a new_argv $argv[$i]
				end
			end
			set argv $new_argv
		end
		
		if contains -- --qssh-update-cache $argv
			__qssh_db_mru_table __qssh_mru_autocomplete_host_table_cb | flock "$__qssh_db_autocomplete_cache_file" sh -c "cat > '$__qssh_db_autocomplete_cache_file'"
			set -x cnt_control_persist_checks 0
			__qssh_db_mru_table __qssh_mru_pick_table_cb | flock "$__qssh_db_skim_cache_file" sh -c "cat > '$__qssh_db_skim_cache_file'"
			return
		else if contains -- --qssh-self-launch $argv
			# launch qssh in a way that resembles interactive use
			# this workaround makes qssh work as intended when ctrl-c is pressed
			if ! isatty 1 || ! isatty 0
				__qssh_echo_interactive "Not a terminal!"
				exit 1
			end
			set -e argv[(contains --index -- --qssh-self-launch $argv)]
			if contains -- --qssh-no-sleep $argv
				set -e argv[(contains --index -- --qssh-no-sleep $argv)]
				set __qssh_self_launch_instant_exit yes
			else
				function __qssh_self_launch_delay_exit --on-event fish_exit
					__qssh_echo_interactive (set_color ff0)'Waiting 5 seconds before exit ...'(set_color white)
					sleep 5
				end
				set __qssh_self_launch_instant_exit no
			end
			# disabling all functionality that might change the window title
			# NOTE: we want the window title to survive at least until ssh connected! (multipick mode)
			#function fish_prompt; end;
			function fish_right_prompt; end;
			function fish_title; end;
			function fish_greeting; end;
			set -l hack_argv $argv
			set -g __qssh_second_iteration no
			#set -eg __qssh_nested
			function fish_prompt
				commandline "__qssh_autorun"
				commandline -f execute
			end
			function __qssh_autorun -V hack_argv -V __qssh_self_launch_instant_exit
				clear
				set -l no_exit
				if [ "$__qssh_second_iteration" = "yes" ]
					read -n1 -P "Press enter to continue, q to exit ... " --local answer
					if [ "$answer" = "q" ]
						exit
					else
						set no_exit yes
					end
				end
				set -g __qssh_second_iteration yes
				
				set hack_argv (string escape -- $hack_argv)
				__qssh_window_title_idle
				__qssh_echo_interactive -en '\e[1A\e[2K'
				qssh $hack_argv
				set -l qssh_exit
				
				if [ "$__qssh_self_launch_instant_exit" = "no" ]
					__qssh_echo_interactive 'Exit Status: '$qssh_exit
				end
				if [ "$no_exit" != "yes" ]
					exit $ssh_exit
				end
			end
			return
		else if contains -- --qssh-multipick-preview $argv
			set -e argv[(contains --index -- --qssh-multipick-preview $argv)]
			__qssh_multipick_help
			return
		else if contains -- --qssh-autocomplete-host $argv
			if __qssh_cache_valid "$__qssh_db_autocomplete_cache_file"
				cat "$__qssh_db_autocomplete_cache_file"
			else
				__qssh_db_mru_table __qssh_mru_autocomplete_host_table_cb
			end
			return $status
		else if contains -- --qssh-export-db $argv
			if contains -- --qssh-export-with-header $argv
				__qssh_db_mru_connect
				for field in $__qssh_db_mru_fields
					echo -n "$field"\t
				end
				echo
			end
			__qssh_db_mru_table __qssh_mru_export_table_cb
			return $status
		else if contains -- --qssh-compact-db $argv
			__qssh_db_mru_consolidate
			return $status
		else if contains -- --qssh-noop $argv
			return 0
		else if contains -- --qssh-fingerprint $argv
			set -e argv[(contains --index -- --qssh-fingerprint $argv)]
			__qssh_parse_connect_args $argv
			__qssh_fingerprint
			return $status
		else if contains -- --qssh-read $argv
			set -e argv[(contains --index -- --qssh-read $argv)]
			__qssh_db_mru_read mru $argv
			set -l read_status $status
			if [ $read_status -eq 0 ]
				for field in $__qssh_db_mru_fields
					set -l vname "mru_$field"
					set -l esc_val (string escape -- $$vname)
					echo "$field=$esc_val"
				end
			else
				echo "No match found" 1>&2
			end
			return $read_status
		else if contains -- --qssh-exit $argv
			set -e argv[(contains --index -- --qssh-exit $argv)]
			__qssh_exit $argv
			return 0
		else if contains -- --qssh-set-custom-ssh-login $argv
			set -l setvar custom_ssh_login
			set -l i1 (contains --index -- --qssh-set-custom-ssh-login $argv)
			set -l i2 (math $i1 + 1)
			set -l setvalue $argv[$i2]
			set -e argv[$i1]
			set -e argv[$i1]
			__qssh_db_mru_read mru $argv
			set mru_$setvar $setvalue
			__qssh_db_mru_write mru $argv
			__qssh_cache_update
			return 0
		else if contains -- --qssh-set-nick $argv
			set -l i1 (contains --index -- --qssh-set-nick $argv)
			set -l i2 (math $i1 + 1)
			set -l nickname $argv[$i2]
			set -e argv[$i1]
			set -e argv[$i1]
			__qssh_db_mru_read mru $argv
			set mru_nickname $nickname
			__qssh_db_mru_write mru $argv
			__qssh_cache_update
			return 0
		else if contains -- --qssh-preview $argv
			# preview pane for skim
			set -e argv[(contains --index -- --qssh-preview $argv)]
			# NOTE: qssh-preview should be called with the hostdef as a single arg
			# as done by skim!
			if [ (count $argv) -eq 0 ]
				echo "Error: hostdef required" 1>&2
				return 1
			else if [ (count $argv) -eq 1 ]
				echo "$argv" | read --tokenize --list argv
			end
			#echo "Arg count: "(count $argv)
			if contains -- '--' $argv
				set -e argv[(contains --index -- '--' $argv)]
			end
			
			if ! __qssh_parse_connect_args $argv
				echo "Error parsing connect args!"
			end
			__qssh_db_mru_read mru $hostdef
			
			echo "Connection:"
			echo "$hostdef"
			if [ "$mru_nickname" != "" ]
				echo "\"$mru_nickname\""
			end
			echo
			echo "Connection settings:"
			
			if [ "$mru_hostdef" = "" ]
				echo "Not in MRU: $hostdef"
				return 0
			end
			
			echo -n "Host key check mode: "
			if [ "$mru_no_host_key" = "yes" ]
				echo (set_color f00)"[!] NO HOST KEY CHECK"(set_color white)
			else if [ "$mru_tmp_host_key" = "yes" ]
				echo (set_color ff0)"[A] "(set_color white)"Alternative host key file"
			else
				echo "[n] Normal"
			end
			
			echo -n "ControlMaster: "
			if __qssh_check $mru_hostdef
				echo -n (set_color green)"[R] RUNNING "(set_color white)
				echo
				echo "ControlPath:"
				echo -n "$controlPath"
			else
				if [ "$mru_no_persist" = "yes" ]
					echo -n "[d] disabled "
				else
					echo -n "[_] inactive / [.] unchecked"
					echo
					echo "ControlPath:"
					echo -n "$controlPath"
				end
			end
			echo
			
			echo "Date created: $mru_time_created"
			if [ "$mru_time_mru" != "" ]
				echo "Date last used: $mru_time_mru"
				echo "Last IP: $mru_last_ip"
				echo "Last IPv4: $mru_last_ipv4"
				echo "Last IPv6: $mru_last_ipv6"
				echo "Count used: $mru_cnt_used"
			end
			
			__qssh_mru_pick_help
			
			return 0
		end
		
		__qssh_mru_connect $argv
		return $status
		
	else
		if set -q __qssh_nested
			__qssh_echo_interactive "Nested shell! exit or unset __qssh_nested if you know what you're doing"
			return 3
		else
			set -x __qssh_nested yes
			__qssh_mru_pick
		end
	end
end

function __qssh_multipick_help
	echo (set_color -b white)(set_color red)"Multipick Mode"
	echo -n (set_color -b black)(set_color white)
	echo
	#cho "Alt-T: Cycle host key modes (normal / alt / none) |"
	echo "In Multipick Mode you can select multiple hosts"
	echo "with [tab]. Most notably this allows opening "
	echo "connections to all selected hosts at once, with"
	echo "keyboard input mirrored to all of them."
	echo
	echo "tmux is used for window management."
	echo 
	echo "Keyboard shortcuts:"
	echo "F1: Display this help (q to exit)"
	echo "Alt-M: Connect to all, one window, mirror keyboard"
	echo "Alt-O: Connect to all, one window"
	echo "Alt-S: Sort"
	echo "Enter: Connect to all in dedicated windows"
	echo "Tab: Toggle selection"
	# TODO: echo "F8: Remove connection"
	# TODO: echo "Alt-X: Terminate running conn"
	# TODO: echo "Alt-K: Remove all host keys for this conn"
	# TODO: echo "Alt-T: Cycle host key modes (normal / alt / none)"
	# TODO: echo "Alt-P: Toggle persistent control connection"
	echo "Esc: Clear query / Exit Multipick"
	echo "F10: Exit Multipick"
	echo
end

function __qssh_mru_pick_help
	echo
	echo "Keyboard shortcuts:"
	echo "F1: Display this help (q to exit)"
	echo "Enter: Connect / Create"
	echo "Alt-N: New connection"
	echo "F3: SFTP with mc"
	echo "F4: Edit connection"
	echo "F5: Duplicate connection"
	echo "F6: Set nickname"
	echo "F8: Remove connection"
	echo "Alt-A: Connect with agent forwarding"
	echo "Alt-X: Terminate running conn"
	echo "Alt-K: Remove all host keys for this conn"
	echo "Alt-T: Cycle host key modes (normal / alt / none)"
	echo "Alt-P: Toggle persistent control connection"
	echo "Alt-S: Sort"
	echo "Alt-M: Multipick"
	echo "Ctrl-R: Reload qssh"
	echo "Ctrl-O: Open local shell"
	echo "Esc: Clear query / Exit"
	echo "F10: Exit"
	echo
	#echo "Legend:"
	#echo "[A]ctive peristent connection"
	#echo "- Not [a]ctive"
	#echo "- Not checked [.]"
end

function __qssh_mru_update
	__qssh_parse_connect_args $argv
	
	# if hostdef_cmd set, do not perform mru update
	# also, when history is disabled temporarily
	if [ "$hostdef_cmd" != "" -o "$__qssh_disable_history" = "yes" ]
		return
	end
	
	# read existing mru entry
	__qssh_db_mru_read mru $hostdef
	#echo $mru_time_mru
	#return 101

	# write updated mru entry to database
	set -l mru_hostdef $hostdef
	set -l mru_cnt_used (math $mru_cnt_used + 1)
	set -l mru_time_mru (date '+%Y-%m-%d %H:%M:%S')
	# not updating IPs here
	__qssh_db_mru_write mru
	
	#return 102
end

function __qssh_master_connect
	__qssh_parse_connect_args $argv
	__qssh_window_title_ssh $argv
	set -e addOpt
	if set -q __qssh_no_host_key
		__qssh_echo_interactive "WARNING: Host key check disabled!"
		set -a addOpt -o StrictHostKeyChecking=no -o CheckHostIP=no -o UserKnownHostsFile=/dev/null
	else if set -q __qssh_tmp_host_key
		__qssh_echo_interactive "Temporary host key enabled"
		set -a addOpt -o UserKnownHostsFile=$__qssh_tmp_host_file
	end
	if set -q __qssh_no_persist
		set -a addOpt -o ControlPersist=60s
	else
		set -a addOpt -o ControlPersist=900s
	end
	if ! set -q __qssh_nobatch
		set opt_batchmode -o BatchMode=yes
	else
		set -e opt_batchmode
	end
	
	#echo "hostdef_userhost: $hostdef_userhost"
	#echo "hostdef_user: $hostdef_user"
	#echo "hostdef_hostname: $hostdef_hostname"
	#echo "hostdef_port: $hostdef_port"

	#echo "Master connection"
	
	# connectivity pre-flight: defaults for non-jumphost hostdef
	set -l connect_hostname $hostdef_hostname
	set -l connect_user $hostdef_user
	set -l connect_port $hostdef_port
	# parse jumphost list if present
	if set -q hostdef_jumphost
		# split list on comma
		set -l list_jumphosts (string split -- ',' $hostdef_jumphost)
		set -l first_jumphost $list_jumphosts[1]
		# reset connect_* to defaults
		set connect_user $__qssh_default_user
		set connect_port 22
		# parse user
		if string match -q -- '*@*' $first_jumphost
			set first_jumphost (string split -- '@' $first_jumphost)
			set connect_user $first_jumphost[1]
			set first_jumphost $first_jumphost[2]
		end
		# parse port
		if string match -q -- '*:*' $first_jumphost
			set first_jumphost (string split -- ':' $first_jumphost)
			set connect_port $first_jumphost[2]
			set first_jumphost $first_jumphost[1]
		end
		set connect_hostname $first_jumphost
	end
	
	if set -q hostdef_jumphost
		__qssh_echo_interactive "Proxy connection to $hostdef_user@$hostdef_hostname:$hostdef_port via $hostdef_jumphost ..."
	else
		# test if master connection already exists and is alive
		if __qssh_check $hostdef
			# present master connection 
			__qssh_echo_interactive "Sharing connection $controlPath ..."
			return 0
		end
		
		__qssh_echo_interactive "New connection $controlPath ..."
	end
	#echo connect_hostname $connect_hostname
	#echo connect_user $connect_user
	#echo connect_port $connect_port
	
	begin
		# Handle resolver errors, guess connected IP ...
		__qssh_db_mru_read mru $hostdef
		set -l resolved_host (__qssh_resolve "$connect_hostname" $opt_ip46)
		if [ (count $resolved_host) -lt 1 ]
			__qssh_echo_interactive "Host does not resolve: $connect_hostname"
			__qssh_echo_interactive "Last known IPs:"
			set -l last_known (begin
				__qssh_echo_interactive $mru_last_ip
				__qssh_echo_interactive $mru_last_ipv4
				__qssh_echo_interactive $mru_last_ipv6
			end | sort | uniq)
			if [ "$last_known" != "" ]
				__qssh_echo_interactive $last_known
			else
				__qssh_echo_interactive "None"
			end
			return 1
		end
		if [ (count $resolved_host) -gt 1 ]
			__qssh_echo_interactive "Warning: Host resolved to multiple IPs"
			__qssh_echo_interactive $resolved_host
		end
		
		set -l resolved_host $resolved_host[1]
		if [ "$mru_last_ip" != "" -a "$resolved_host" != "$mru_last_ip" ]
			__qssh_echo_interactive "Notice: Resolved IP changed from $mru_last_ip to $resolved_host"
		end
		if ! nc -w 1 -z $resolved_host $connect_port &> /dev/null
			__qssh_echo_interactive "Host is down: $resolved_host port $connect_port"
			__qssh_echo_interactive -n "Waiting for connectivity ..."
			while ! nc -w 1 -z $resolved_host $connect_port &> /dev/null
				sleep 1
				__qssh_echo_interactive -n '.'
			end
			__qssh_echo_interactive
		end
		
		# consider successful, update mru
		if [ "$__qssh_disable_history" != "yes" ]
			set -l mru_hostdef $hostdef
			set -l mru_last_ip $resolved_host
			set -l mru_last_ipv4 (__qssh_resolve_ipv4 "$connect_hostname" | head -n1)
			set -l mru_last_ipv6 (__qssh_resolve_ipv6 "$connect_hostname" | head -n1)
			
			__qssh_db_mru_write mru
		end
	end
	
	if set -q hostdef_jumphost
		return 0
	end
	
	#echo "$ssh_ccheck_errors"
	#echo "exit $ssh_ccheck_exit"
	# opening the peristent control connection
	#set sshErrors (ssh $opt_A $opt_ip46 $opt_batchmode $addOpt -o ControlMaster=auto -o ControlPath=$controlPath -o ExitOnForwardFailure=yes -N -f -p $hostdef_port -l $hostdef_user $hostdef_hostname 2>&1)
	set sshErrors (ssh $opt_A $opt_ip46 $opt_batchmode $addOpt -o ControlMaster=$controlMasterAuto -o ControlPath=$controlPath -o ExitOnForwardFailure=yes -N -f -p $connect_port -l $connect_user $connect_hostname 2>&1)
	set sshExit $status
	if [ $sshExit -ne 0 ]
		#for line in $sshErrors; echo "! $line"; end
		# parse for common problems like host key mismatch, ask for mitigation
		if string match -q -- "*REMOTE HOST IDENTIFICATION HAS CHANGED*" "$sshErrors"
			if set -q __qssh_tmp_host_key
				__qssh_echo_interactive "Attention: Host key mismatch (temporary known_hosts), eavesdropping possible."
				read -n1 -P "(a)bort, (c)onnect anyways, (r)emove temporary host key information > " answer
			else
				__qssh_echo_interactive "Attention: Host key mismatch, eavesdropping possible."
				__qssh_fingerprint
				read -n1 -P "(a)bort, (c)onnect anyways, (r)emove host key information, (t)emporary host key > " answer
			end
			switch $answer
				case c
					__qssh_no_host_key=yes __qssh_master_connect $hostdef
					return $status
				case t
					__qssh_tmp_host_key=yes __qssh_master_connect $hostdef
					return $status
				case r
					for line in $sshErrors
						#echo "!! $line"
						if string match -q -- "*keygen*" "$line"
							eval set sshKeyGenCmd $line
							break
						end
					end

					if [ "$sshKeyGenCmd" != "" ]
						__qssh_remove_keys $sshKeyGenCmd
						# this doesn't remove related IP keys, so we improve ssh-keygen -R
						#eval $sshKeyGenCmd
						__qssh_master_connect $hostdef
						return $status
					else
						__qssh_echo_interactive "Error: cannot find removal instruction in output"
						return 1
					end
			end
			return $sshExit
		else if string match -q -- "*Permission denied (*password*)*" "$sshErrors"
			__qssh_echo_interactive "Password required ..."
			set -x __qssh_nobatch yes
			__qssh_master_connect $hostdef
			set -l cmd_copy_id "ssh-copy-id $hostdef_user@$hostdef_hostname -p$hostdef_port -o ControlPath=$controlPath"
			__qssh_echo_interactive "$cmd_copy_id"
			read -n1 -P "Copy your public keys to authorized_keys file like this? (y/N) > " answer
			if [ "$answer" = "y" ]
				eval $cmd_copy_id
			end
			return $status
		else if string match -q -- "*key verification failed*" "$sshErrors"
			__qssh_echo_interactive "Host key unknown! Host offers these fingerprints:"
			__qssh_fingerprint
			# using ssh for host key confirmation, as we don't know how to edit known_hosts safely yet
			# keeping true stdin with echo ""
			echo "" | ssh $addOpt $opt_ip46 -o BatchMode=no -o ControlPath=none -l $hostdef_user -p $hostdef_port $hostdef_hostname /bin/true
			set confirm_status $status
			if [ $confirm_status -eq 0 ]
				__qssh_master_connect $hostdef
				return $status
			else
				return $confirm_status
			end
			# old idea: scan fingerprints, ask user to accept key
			#__qssh_fingerprint
			#read -n1 -P "Accept fingerprint? (y)es / (n)o > " answer
			#if [ "$answer" = "y" ]
			#	
			#end
		else
			__qssh_echo_interactive "SSH exit status: $sshExit"
			for line in $sshErrors
				__qssh_echo_interactive "$line"
			end
			__qssh_pause
		end
		return $sshExit
	else
		for line in $sshErrors
			__qssh_echo_interactive "!! $line"
		end
	end
	#__qssh_echo_interactive "Master connect OK"
	return 0
end

function __qssh_slave_connect
	__qssh_parse_connect_args $argv
	# NOTE: "broken pipe" case not handled perfect yet
	set -l sshprog
	if set -q __qssh_custom_ssh_login
		set sshprog $__qssh_custom_ssh_login
	else
		set sshprog ssh
	end
	$sshprog $opt_ip46 -o ExitOnForwardFailure=yes -o ControlMaster=no -o ControlPath=$controlPath -p $hostdef_port -l $hostdef_user $hostdef
	
	set ssh_exit $status
	if set -q __qssh_no_persist
		ssh -o ControlPath=$controlPath -O exit $hostdef
	end
	return $ssh_exit
end

function __qssh_parse_connect_args --no-scope-shadowing
	# remaining argv is host definition
	set hostdef $argv
	if ! __qssh_parse_hostdef $hostdef
		return 1
	end
	argparse --ignore-unknown 'A' '#-ip46' -- $argv

	if set -q _flag_A
		set opt_A -A
	else
		set -e opt_A
	end
	if set -q _flag_ip46
		set opt_ip46 -$_flag_ip46
	else
		set -e opt_ip46
	end
	
	set -l cp_hostdef $hostdef
	if [ "$hostdef_cmd" != "" ]
		# remove cmd from hash
		set -e cp_hostdef[(contains --index -- "$hostdef_cmd" $cp_hostdef)]
	end
	set -a cp_hostdef $hostdef_user
	set -a cp_hostdef $hostdef_port
	# NOTE: length of unix domain socket limited! | string sub -l 8
	set controlPathSuffix (echo $cp_hostdef | $__name_md5sum | string replace --regex -- ' .*' '')
	if set -q hostdef_jumphost
		# Jumphost does not support controlPath, as it seems
		set controlPath none
		set controlMasterAuto no
	else
		set controlPath "$__qssh_controlpath_prefix""$controlPathSuffix"
		set controlMasterAuto auto
	end
	return 0
end

function __qssh_exit
	__qssh_parse_connect_args $argv
	if ssh -o ControlPath=$controlPath -O check $hostdef &> /dev/null
		ssh -o ControlPath=$controlPath -O exit $hostdef &> /dev/null
	end
end

function __qssh_check
	__qssh_parse_connect_args $argv
	ssh -o ControlPath=$controlPath -O check $hostdef &> /dev/null
	return $status
end

function __qssh_parse_hostdef --no-scope-shadowing
	# set hostdef_hostname, hostdef_user, hostdef_port

	# using argparse to strip all known ssh arguments (with values) from $argv
	argparse --ignore-unknown \
		# port and login used by ourselves \
		'p=' 'l=' \
		# other \
		'B=' 'b=' 'c=' 'D=' 'E=' 'e=' 'F=' 'I=' 'i=' 'J=' 'L=' 'm=' 'O=' 'o=' 'Q=' 'R=' 'S=' 'W=' 'w=' \
		-- $argv

	#echo "Remaining argv: $argv"
	if set -q _flag_p
		set hostdef_port $_flag_p
	else
		set hostdef_port 22
	end
	
	if set -q _flag_J
		set hostdef_jumphost $_flag_J
	else
		set -e hostdef_jumphost
	end
	
	# walk remains as positional arguments
	set -l posarg 0
	set hostdef_userhost ''
	set hostdef_cmd ''
	for hostdef_arg in $argv
		if ! string match -q -- "-*" $hostdef_arg
			set posarg (math $posarg + 1)
			if [ $posarg -eq 1 ]
				# first positional argument is the hostname or user + host combination
				set hostdef_userhost $hostdef_arg
			else if [ $posarg -eq 2 ]
				# second positional argument is remote command
				set hostdef_cmd $hostdef_arg
				break
			end
		end
	end
	if ! set -q hostdef_userhost
		__qssh_echo_interactive "Error: no ssh hostdef!"
		return 1
	end
	if string match -q -- "*@*" $hostdef_userhost
		set hostdef_user (string replace --regex -- "@.+" "" $hostdef_userhost)
		set hostdef_hostname (string replace --regex -- "[^@]+@" "" $hostdef_userhost)
	else
		set hostdef_hostname $hostdef_userhost
	end

	if ! set -q hostdef_user
		if set -q _flag_l
			set hostdef_user $_flag_l
		else
			set hostdef_user $__qssh_default_user
		end
	end
	
	return 0
end

# MRU database storing
# - hostdef
# - cnt_used
# - created_on
# - used_on
# - last_ip
# - flags:
#   - tmp_host_key: always use temporary host key (toggle)
#   - no_host_key: disable host key checking (toggle)
#   - no_persist: disable ControlPersist (set to 5s, send exit on quit, individual random socket)

function __qssh_db_mru_connect --no-scope-shadowing
	# NOTE: position of "deleted" is hardcoded as line[9]
	set __qssh_db_mru_fields \
		hostdef \
		time_mru \
		time_created \
		cnt_used \
		last_ip \
		tmp_host_key \
		no_host_key \
		no_persist \
		deleted \
		last_ipv4 \
		last_ipv6 \
		nickname \
		custom_ssh_login
end

function __qssh_db_mru_row --no-scope-shadowing -d \
	'initialize empty row fields with $prefix'
	set -l prefix $argv[1]
	__qssh_db_mru_connect
	for field in $__qssh_db_mru_fields
		set "$prefix""_""$field" ""
	end
end

function __qssh_db_mru_write --no-scope-shadowing -d \
	'write a row to the db with values from $prefix'
	set -l prefix $argv[1]
	__qssh_db_mru_connect
	set -l line
	set -l sep ""
	
	for field in $__qssh_db_mru_fields
		set -l vname "$prefix""_""$field"
		# escaping as a single operation to prevent corruption (by cartesian product?)
		set -l escaped (string escape -- $$vname)
		set line "$line""$sep""$escaped"
		set -l sep \t
	end
	# lock file before writing to it (closes #23)
	echo "$line" | flock "$__qssh_db_mru_file" sh -c "cat >> '$__qssh_db_mru_file'"
end

function __qssh_db_mru_delete -d \
	'delete a row (virtually)'
	set -l hostdef $argv
	
	__qssh_db_mru_row mru
	set -l mru_hostdef $hostdef
	set -l mru_deleted deleted
	__qssh_db_mru_write mru
end

function __qssh_db_mru_read --no-scope-shadowing -d \
	'read a specific row into $prefix with key matching $val'
	set -l prefix $argv[1]
	set -e argv[1]
	set -l val $argv
	
	__qssh_db_mru_connect
	# start with empty row
	__qssh_db_mru_row $prefix
	
	# taking care to match heavily escaped strings as key
	set -l match ""
	if [ -e "$__qssh_db_mru_file" ]
		for line in (tac "$__qssh_db_mru_file")
			set -l line (string split -- \t $line)
			set -l lkey (string unescape -- $line[1])
			if [ "$lkey" = "$val" ]
				set match $line
				break
			end
		end
	end
	
	if [ "$match" != "" ]
		#echo "M:""$match"
		# matched: walk fields and set to unescaped values
		__qssh_db_mru_unfold match $prefix
		set -l vdel "$prefix""_deleted"
		if [ "$$vdel" = "deleted" ]
			# virtually deleted - cancel match
			__qssh_db_mru_row $prefix
			return 2
		end
		return 0
	else
		# return empty row as initialized by __qssh_db_mru_row
		return 1
	end
end

function __qssh_db_mru_unfold --no-scope-shadowing
	#__qssh_db_mru_connect
	set -l vmatch $argv[1]
	set -l match $$vmatch
	set -l prefix $argv[2]
	set -l fidx 0
	for field in $__qssh_db_mru_fields
		set fidx (math $fidx + 1)
		if set -q match[$fidx]
			# upwards compatible
			echo "$match[$fidx]" | read --tokenize --list "$prefix""_""$field"
		else
			set "$prefix""_""$field" ''
		end
	end
	
end

function __qssh_mru_connect -d \
	'connect using extended parameters from mru db'
	
	set -l hostdef $argv
	
	# trigger compact db every whensoever
	#echo "Next DB consolidation in "$__qssh_countdown_compact_db" edits"
	if [ "$__qssh_countdown_compact_db" = "" ]
		set --universal __qssh_countdown_compact_db $__qssh_interval_compact_db
	else
		set --universal __qssh_countdown_compact_db (math $__qssh_countdown_compact_db - 1)
		if [ $__qssh_countdown_compact_db -lt 1 ]
			set --universal __qssh_countdown_compact_db $__qssh_interval_compact_db
			__qssh_db_mru_consolidate
		end
	end
	
	__qssh_db_mru_read mru $hostdef
	
	# set -l is_new_hostdef
	# if [ "$mru_hostdef" = "" ]
	# 	set is_new_hostdef yes
	# end
	if [ "$mru_tmp_host_key" = "yes" ]
		set -x __qssh_tmp_host_key yes
	end
	if [ "$mru_no_host_key" = "yes" ]
		set -x __qssh_no_host_key yes
	end
	if [ "$mru_no_persist" = "yes" ]
		set -x __qssh_no_persist yes
	end
	
	__qssh_mru_update $hostdef
	__qssh_cache_update
	
	__qssh_master_connect $hostdef
	set master_exit $status
	if [ $master_exit -eq 0 ]
		set -l __qssh_custom_ssh_login
		if [ "$mru_custom_ssh_login" != "" ]
			set -x __qssh_custom_ssh_login $mru_custom_ssh_login
		else
			set -e __qssh_custom_ssh_login
		end
		__qssh_slave_connect $hostdef
		return $status
	else
		return $master_exit
	end
end

function __qssh_db_mru_consolidate -d \
	'write out new database with obsolete information removed'
	if [ ! -e "$__qssh_db_mru_file" ]
		__qssh_echo_interactive "Blank MRU database"
		return 0
	end
	__qssh_echo_interactive -n "qssh compact db:"
	set -l __qssh_db_mru_file_new "$__qssh_db_mru_file"".new"
	set -l __qssh_db_mru_file_bak "$__qssh_db_mru_file"".bak"
	if [ -e "$__qssh_db_mru_file_new" ]
		__qssh_echo_interactive "Error: File exists, delete if no other process is using it:"
		__qssh_echo_interactive "$__qssh_db_mru_file_new"
		return 5
	end
	__qssh_echo_interactive -n " [dump]"
	# NOTE: reverse output order with tac!
	__qssh_db_mru_table __qssh_mru_export_table_cb | tac | flock "$__qssh_db_mru_file_new" sh -c "cat > '$__qssh_db_mru_file_new'"
	__qssh_echo_interactive -n " [rm .bak]"
	rm -f "$__qssh_db_mru_file_bak"
	__qssh_echo_interactive -n " [mk .bak]"
	mv "$__qssh_db_mru_file" "$__qssh_db_mru_file_bak"
	__qssh_echo_interactive -n " [mv .new ]"
	mv "$__qssh_db_mru_file_new" "$__qssh_db_mru_file"
	#__qssh_echo_interactive -n " [test]"
	#__qssh_db_mru_table __qssh_mru_export_table_cb > /dev/null
	__qssh_echo_interactive " [done]"
end

function __qssh_db_mru_table -d \
	'read whole database discarding obsolete information, call $callback for every line'
	set -l callback $argv[1]
	__qssh_db_mru_connect
	set -l makeuniq
	if [ ! -e "$__qssh_db_mru_file" ]
		return 0
	end
	for line in (tac "$__qssh_db_mru_file")
		if [ "$line" != "" ] # ignore blank lines
			set line (string split -- \t $line)
			if ! contains -- "$line[1]" $makeuniq
				set -a -- makeuniq "$line[1]"
				if [ "$line[9]" = "deleted" ]
					# virtually deleted - skip this hostdef entirely
					continue
				end
				echo "$line[1]" | read --local --tokenize --list hostdef
				__qssh_db_mru_unfold line mru
				$callback
			end
		end
	end
end

function __qssh_mru_export_table_cb --no-scope-shadowing
	set -l line
	set -l sep ""
	
	for field in $__qssh_db_mru_fields
		set -l vname "mru_""$field"
		if [ (count $$vname) -eq 0 ]
			#set line "$line""$sep"(string escape -- "cntfail[$field]:"(count $$vname))
			set line "$line""$sep""''"
		else
			set line "$line""$sep"(string escape -- $$vname)
		end
		set -l sep \t
	end
	echo "$line"
end

function __qssh_mru_autocomplete_host_table_cb --no-scope-shadowing -d \
	'Outputs a list of autocomplete options for completion. Adds :qssh suffix where necessary to expand properly.'
	set -l line
	set -l sep ""
	if [ (count $mru_hostdef) -gt 1 ]
		set -l unesc_hostdef (string escape -- $mru_hostdef | string join -- ' ')
		echo $unesc_hostdef':qssh'\t$mru_nickname
	else
		set -l unesc_hostdef (string escape -- $mru_hostdef | string join -- ' ')
		echo $unesc_hostdef\t$mru_nickname
	end
end

function __qssh_mru_pick_tag --no-scope-shadowing
	echo -n "["
	set_color white
	if [ $cnt_control_persist_checks -gt 0 ]
		if ! __qssh_parse_connect_args $hostdef
			echo -n "E"
		else
			if [ "$mru_no_persist" = "yes" ]
				# NOTE: while it is possible to have a dangling persistant connection,
				# it is rare and would be a bug. So why not have performance here ...
				echo -n "d"
			else
				if __qssh_check $hostdef
					echo -n (set_color green)"R"(set_color white)
				else
					set cnt_control_persist_checks (math $cnt_control_persist_checks - 1)
					echo -n "_"
				end
			end
		end
	else
		if [ "$mru_no_persist" = "yes" ]
			echo -n "d"
		else
			echo -n "."
		end
	end
	# NOTE: using more simple colors, fish 3.1.0 seems to disturb skim?
	if [ "$mru_no_host_key" = "yes" ]
		echo -en (set_color f00)"!"(set_color white)
	else if [ "$mru_tmp_host_key" = "yes" ]
		echo -n (set_color ff0)"A"(set_color white)
	else
		echo -n "n"
	end
	
	set_color white
	echo -n ']'
end

function __qssh_mru_pick_table_cb --no-scope-shadowing
	echo -n "-- "
	echo -n (string escape -- $hostdef)
	echo -ne "\t"
	
	__qssh_mru_pick_tag
	
	echo -ne "\t"
	if [ "$mru_nickname" != "" ]
		echo -n "\"$mru_nickname\""
	end
	echo
end

function __qssh_mru_pick_refresh_data
	while read line
		if [ $cnt_control_persist_checks -gt 0 ]
			# update cached item IF persistent connections are allowed
			set sline (string split -- \t $line)
			
			# mru_* vars
			if string match -q -- '*d*' $sline[2]
				set mru_no_persist yes
				# shortcut here
				echo $line
				continue
			else
				set -e mru_no_persist
			end
			if string match -q -- '*A*' $sline[2]
				set mru_tmp_host_key yes
			else
				set -e mru_tmp_host_key
			end
			if string match -q -- '*!*' $sline[2]
				set mru_no_host_key yes
			else
				set -e mru_no_host_key
			end
			
			# reconstruct mru-like entry
			echo (string replace --regex -- '^-- ' '' "$sline[1]") | read --tokenize --list hostdef
			#echo (string escape $hostdef)
			#return
			set sline[2] (__qssh_mru_pick_tag)
		
			echo (string join -- \t $sline)
		else
			echo $line
		end
	end
end

function __qssh_mru_pick_data
	set -x cnt_control_persist_checks $__qssh_mru_pick_control_persist_checks
	if __qssh_cache_valid $__qssh_db_skim_cache_file
		cat $__qssh_db_skim_cache_file | __qssh_mru_pick_refresh_data
	else
		# update cache in background
		__qssh_cache_update
		__qssh_db_mru_table __qssh_mru_pick_table_cb
	end
end

function __qssh_mru_pick -d \
	'Menu to work on MRU ssh list'
	set -x query
	set -l _flag_sort "no"
	while true
		__qssh_window_title_idle
		if [ "$query" != "" ]
			set opt_query "--query=$query"
		else
			set opt_query "--query="
		end
		if [ "$_flag_sort" = "yes" ]
			set opt_sort sort
		else
			set opt_sort cat
		end
		
		set -l answer (\
			__qssh_mru_pick_data | \
			$opt_sort | \
			sk \
				$opt_query \
				--no-multi \
				--bind \
					'enter:if-non-matched(execute:echo {q}; echo --instant-new+abort)+execute(echo {q}; echo {1})+abort,'\
					'alt-n:execute(echo {q}; echo --new)+abort,'\
					'f1:execute(echo {q}; echo --help)+abort,'\
					'f3:execute(echo {q}; echo --scp {1})+abort,'\
					'f4:execute(echo {q}; echo --edit {1})+abort,'\
					'f5:execute(echo {q}; echo --duplicate {1})+abort,'\
					'f6:execute(echo {q}; echo --nickname {1})+abort,'\
					'f8:execute(echo {q}; echo --remove {1})+abort,'\
					'alt-a:execute(echo {q}; echo --agent-connect {1})+abort,'\
					'alt-x:execute(echo {q}; echo --exit {1})+abort,'\
					'alt-k:execute(echo {q}; echo --clear-keys {1})+abort,'\
					'alt-t:execute(echo {q}; echo --toggle-key-check {1})+abort,'\
					'alt-m:execute(echo {q}; echo --multipick {1})+abort,'\
					'alt-p:execute(echo {q}; echo --toggle-persist {1})+abort,'\
					'alt-s:execute(echo {q}; echo --sort)+abort,'\
					'ctrl-r:execute(echo {q}; echo --reload)+abort,'\
					'ctrl-o:execute(echo {q}; echo --local-shell)+abort,'\
					\
					'alt-q:execute(echo ""; echo --quit)+abort,'\
					'ctrl-c:execute(echo ""; echo --quit)+abort,'\
					'ctrl-d:execute(echo ""; echo --quit)+abort,'\
					'esc:if-query-empty:execute(echo ""; echo --quit)+if-query-empty:abort+beginning-of-line+kill-line,'\
					'f10:execute(echo ""; echo --quit)+abort,'\
				--delimiter '\t' \
				--header \
					'F1:Help Ctrl-N:New F10:Quit' \
				--prompt "Search / New SSH: " \
				--reverse \
				--ansi \
				--print-query \
				--preview "echo qssh --qssh-preview {1} | fish" \
				--preview-window "right:50%:wrap" \
				--with-nth 2,1,3 \
				--nth 2,3 \
		)
		set -l sk_exit $status
		#if [ (count $answer) -gt 2 ]
		#	echo "skim bugged"
		#	echo "$answer"
		#	return 1
		#end
		
		echo "$answer[1]" | read --export query
		#set -x query (string unescape -- $answer[1])
		set -l answer (string split -- \t $answer[2])
		#set -l answer (string split -- ' ' $answer[1])
		echo "$answer[1]" | read --tokenize --list answer
		
		if string match -q -- '--sort' $answer
			if [ "$_flag_sort" = "yes" ]
				set _flag_sort "no"
			else
				set _flag_sort "yes"
			end
			continue
		end
		#echo "X:$sk_exit"
		#echo "Q:$query"
		#echo "A:"
		#echo (string escape -- $answer)
		#read -P "debug"
		#return 1
		
		if [ "$answer" = "" ]
			continue
		end
		
		__qssh_exec $answer
		if [ $status -ne 0 ]
			return $status
		end
	end
end

function __qssh_exec --no-scope-shadowing
	argparse 'h/help' 'c/connect' 'x/exit' 'e/edit' 'd/duplicate' \
	  'q/quit' 'r/remove' 'n/new' 'i/instant-new' 'k/clear-keys' \
		't/toggle-key-check' 'p/toggle-persist' \
		'l/local-shell' 'R/reload' 's/scp' 'a/agent-connect' \
		'N/nickname' 'm/multipick' -- $argv
	#echo (count $argv)
	#return 1
	set -l hostdef $argv
	set -l input_ssh_prefix "> ssh "
	
	if set -q _flag_multipick
		__qssh_multipick $query
		return 0
		
	else if set -q _flag_clear_keys
		if __qssh_parse_hostdef $hostdef
			__qssh_db_mru_read mru $hostdef
			__qssh_echo_interactive "Clearing known host keys for $hostdef_hostname $hostdef ..."
			if [ "$mru_tmp_host_key" != "" ]
				__qssh_remove_keys -R "$hostdef_hostname" -f "$__qssh_tmp_host_file"
			else
				__qssh_remove_keys -R "$hostdef_hostname"
			end
		else
			__qssh_echo_interactive "Unable to parse hostdef $hostdef" 1>&2
			return 1
		end
		__qssh_pause
		return 0
		
	else if set -q _flag_new || set -q _flag_instant_new || set -q _flag_duplicate
		__qssh_echo_interactive "New SSH connection - for example: root@server -C -l 'weird name'"
		if set -q _flag_duplicate
			set -l esc_hostdef (string escape -- $hostdef)
			__qssh_prompt -P $input_ssh_prefix -c "$esc_hostdef" --tokenize --list hostdef
		else if [ "$query" != "" ]
			echo $query | read --local --tokenize --list tok_query
			set -l esc_hostdef (string escape -- $tok_query)
			#set -l esc_hostdef $query
			if ! set -q _flag_instant_new
				__qssh_prompt -P $input_ssh_prefix -c "$esc_hostdef" --tokenize --list hostdef
			else
				set hostdef $tok_query
			end
		else
			__qssh_prompt -P $input_ssh_prefix --list --tokenize hostdef
		end
		if [ "$hostdef" != "" ]
			__qssh_db_mru_read mru $hostdef
			if set -q _flag_duplicate
				set query (string escape -- $hostdef)
			end
			if [ "$mru_hostdef" != "" ]
				__qssh_echo_interactive "Error: connection already exists!"
				__qssh_pause
				return 0
			else
				__qssh_db_mru_row mru
				set mru_hostdef $hostdef
				set mru_time_created (date '+%Y-%m-%d %H:%M:%S')
				__qssh_db_mru_write mru
				__qssh_cache_update --wait
				# slight recursion
				__qssh_new_scope __qssh_exec -- $hostdef
				set query (string escape -- $hostdef)
			end
		else
			return 0
		end
		
	else if set -q _flag_remove
		__qssh_exit $hostdef
		__qssh_db_mru_delete $hostdef
		__qssh_cache_invalidate
		
	else if set -q _flag_edit
		set -l old_hostdef $hostdef
		set -l esc_hostdef (string escape -- $hostdef)
		
		__qssh_echo_interactive "Edit SSH connection:"
		if ! __qssh_prompt -P $input_ssh_prefix -c "$esc_hostdef" --tokenize --list hostdef
			return 0
		end
		
		if [ "$old_hostdef" = "$hostdef" ]
			return 0
		end
		# terminate potential connections
		__qssh_exit $old_hostdef
		# parse the answer into $hostdef
		__qssh_parse_connect_args $hostdef
		# rescue old stats and settings
		__qssh_db_mru_read mru $old_hostdef
		set mru_hostdef $hostdef
		__qssh_db_mru_write mru
		__qssh_db_mru_delete $old_hostdef
		
		set query (string escape -- $hostdef)
		__qssh_cache_invalidate
		
	else if set -q _flag_toggle_key_check
		__qssh_db_mru_read mru $hostdef
		if [ "$mru_hostdef" = "" ]
			__qssh_echo_interactive "Cannot toggle on non-existent hostdef $hostdef"
			return 1
		end
		if [ "$mru_tmp_host_key" != "yes" -a "$mru_no_host_key" != "yes" ]
			set mru_tmp_host_key yes
		else if [ "$mru_tmp_host_key" = "yes" -a "$mru_no_host_key" != "yes" ]
			set mru_tmp_host_key ''
			set mru_no_host_key yes
		else
			set mru_tmp_host_key ''
			set mru_no_host_key ''
		end
		__qssh_db_mru_write mru
		__qssh_cache_invalidate
		
	else if set -q _flag_toggle_persist
		__qssh_db_mru_read mru $hostdef
		if [ "$mru_hostdef" = "" ]
			__qssh_echo_interactive "Cannot toggle on non-existent hostdef $hostdef"
			return 1
		end
		if [ "$mru_no_persist" != "yes" ]
			set mru_no_persist yes
			__qssh_exit $hostdef
		else
			set mru_no_persist no
		end
		__qssh_db_mru_write mru
		__qssh_cache_invalidate
		
	else if set -q _flag_help
		__qssh_mru_pick_help | less -R
		
	else if set -q _flag_exit
		__qssh_exit $hostdef
		
	else if set -q _flag_scp
		__qssh_mc_sftp $hostdef
		return 0
		
	else if set -q _flag_nickname
		__qssh_db_mru_read mru $hostdef
		__qssh_echo_interactive "Edit nickname for connection '$hostdef'"
		__qssh_prompt -P "> " -c (string unescape -- $mru_nickname) answer
		or return 0
		set mru_nickname $answer
		__qssh_db_mru_write mru $hostdef
		__qssh_cache_invalidate
		return 0
		
	else if set -q _flag_reload
		function __qssh_tmp_reload
			set -le __qssh_nested
			# TODO: this could be more clean without recursion ...
			source (status filename)
			qssh
		end
		__qssh_clean_env __qssh_tmp_reload
		functions -e __qssh_tmp_reload
		return 1
		
	else if set -q _flag_quit
		return 1
		
	else if set -q _flag_local_shell
		# open a subshell for cases where qssh is the main terminal command
		function __qssh_tmp_subshell
			# blocking signals before executing subshell as a precaution
			block --local
			$SHELL -l -i
		end
		__qssh_clean_env __qssh_tmp_subshell
		functions -e __qssh_tmp_subshell
		return 0
		
	else # just connect
	
	
		__qssh_echo_interactive "Connecting to $hostdef ..."
		set -l __conn_start_time (__sp_getnanoseconds)
		if set -q _flag_agent_connect
			set -lx __qssh_disable_history yes
			set -lx __qssh_no_persist yes
			__qssh_mru_connect $hostdef -A
		else
			__qssh_mru_connect $hostdef
		end
		set -l qssh_exit $status
		set -l qssh_duration (math "round(("(__sp_getnanoseconds)" - $__conn_start_time ) / 1000 / 1000)")
		# on *CLEAN* exit, show prompt to give user a chance to read bad messages from remote
		if [ $qssh_exit -eq 0 -a $qssh_duration -lt 2000 ]
			__qssh_pause "That was quick!"
		end
		# on *UNCLEAN* exit, pause to read potential messages
		if [ $qssh_exit -ne 0 ]
			__qssh_pause "Exit Status: $qssh_exit"
		end
		if [ "$query" = "" ]
			set query (string escape -- $hostdef)
		end
		return $qssh
		
	end
end

function __qssh_multipick -d \
	'Menu to pick multiple hosts, ssh in tmux sync panes'
	set -x query $argv[1]
	# trick status current-command into thinking "qssh" was
	# the most recent command run so fish_title works as expected.
	qssh --qssh-noop && set -l window_title (fish_title qssh)
	# update window title
	echo -ne "\e]0;$window_title\a"
	set -l skim_answer
	set -l hostlist
	set -l _flag_one_window "no"
	set -l _flag_mirror_keyboard "no"
	set -l _flag_sort "no"
	if [ "$__qssh_multipick_cli_argv" = "" ]
		while true
			if [ "$query" != "" ]
				set opt_query "--query=$query"
			else
				set opt_query "--query="
			end
			if [ "$_flag_sort" = "yes" ]
				set opt_sort sort
			else
				set opt_sort cat
			end
			set skim_answer (\
				__qssh_mru_pick_data | \
				$opt_sort | \
				sk \
					$opt_query \
					--multi \
					--color=header:\#ff0000,selected:\#ffff00 \
					--bind \
						'f1:execute(echo {q}; echo --help)+abort,'\
						'esc:if-query-empty:execute(echo ""; echo --quit)+if-query-empty:abort+beginning-of-line+kill-line,'\
						'f10:execute(echo ""; echo --quit)+abort,'\
						'alt-m:execute(echo --mirror-keyboard)+accept,'\
						'alt-o:execute(echo --one-window)+accept,'\
						'alt-s:execute(echo --sort)+accept,'\
					--delimiter '\t' \
					--header \
						'Multipick Mode! F1:Help' \
					--prompt "Search: " \
					--reverse \
					--ansi \
					--print-query \
					--preview "echo qssh --qssh-multipick-preview {1} | fish" \
					--preview-window "right:50%:wrap" \
					--with-nth 2,1,3 \
					--nth 2,3 \
			)
			set sk_exit $status
			
			if string match -q -- '--sort' $skim_answer[1]
				if [ "$_flag_sort" = "yes" ]
					set _flag_sort "no"
				else
					set _flag_sort "yes"
				end
				continue
			end
			
			set _flag_one_window "no"
			if string match -q -- '--one-window' $skim_answer[1]
				set -e skim_answer[1]
				set _flag_one_window "yes"
			end
			
			set _flag_mirror_keyboard "no"
			if string match -q -- '--mirror-keyboard' $skim_answer[1]
				set -e skim_answer[1]
				set _flag_mirror_keyboard "yes"
				set _flag_one_window "yes"
			end
			
			# for item in $skim_answer
			# 	echo "i:"
			# 	echo $item
			# end
			# __qssh_pause
			
			echo "$skim_answer[1]" | read --export query
			#set -x query (string unescape -- $answer[1])
			set -e skim_answer[1]
			
			if string match -q -- '--quit' $skim_answer[1]
				return
			else if string match -q -- '--help' $skim_answer[1]
				__qssh_multipick_help | less -R
				continue
			else
				set -e hostlist
				for answer in $skim_answer
					set -l answer (string split -- \t $answer)
					set -l answer[1] (string replace --regex -- '^-- ' '' $answer[1])
					set -a hostlist "$answer[1]"
				end
				break
			end
		end
	else
		# cli version of multipick
		if contains -- --qssh-one-window $__qssh_multipick_cli_argv
			set -e __qssh_multipick_cli_argv[(contains --index -- --qssh-one-window $__qssh_multipick_cli_argv)]
			set _flag_one_window "yes"
		end
		if contains -- --qssh-mirror-keyboard $__qssh_multipick_cli_argv
			set -e __qssh_multipick_cli_argv[(contains --index -- --qssh-mirror-keyboard $__qssh_multipick_cli_argv)]
			set _flag_one_window "yes"
			set _flag_mirror_keyboard "yes"
		end
		set hostlist $__qssh_multipick_cli_argv
	end
	
	if [ (count $hostlist) -gt 0 ]
		#echo "$answer[1]" | read --tokenize --list answer
		
		set -l tmux_arglist
		set -l i 0
		#	Introducing a slight delay for each connection to prevent some race
		# condition caused by self-launch
		set -l qssh_base_delay (math 20 x (count $hostlist) )
		set -l qssh_base_delay 0
		for answer in $hostlist
			set i (math $i + 1)
			set -l qssh_delay 0
			set -l qssh_delay (math '(' $i x $qssh_delay + $qssh_base_delay ')' / 1000)
			set -l qssh_delay (LC_ALL=C printf "%f" $qssh_delay)
			
			echo "$answer" | read --tokenize --list answer
			__qssh_parse_connect_args $answer
			
			# method 1: prepend complete ssh command
			# this seems to work fine, but it may break master connection stuff
			# could rework this to open master connection beforehand, output "cannot connect"
			# when not possible ...
			#set -l tmux_arg (string escape -- $answer)
			#set -l --prepend tmux_arg ssh $opt_ip46 -o ExitOnForwardFailure=yes -o ControlMaster=no -o ControlPath=$controlPath -p $hostdef_port -l $hostdef_user
			
			# method 2: prepend qssh, which doesn't work out well because input is mangled
			#set -l tmux_arg (string escape -- $answer)
			#set -l --prepend tmux_arg qssh
			
			# method 3: try /usr/local/bin/qssh
			#set -l tmux_arg (string escape -- $answer)
			#set -l --prepend tmux_arg fish -i /usr/local/bin/qssh -- 
			
			# method 4: try fish -i -c directly
			#set -l tmux_arg (string escape -- $answer)
			#set -l --prepend tmux_arg fish -il -c qssh -- 
			
			# method 5: try bad hack (qssh-self-launch)
			set -l tmux_arg $answer
			set -l --prepend tmux_arg qssh --qssh-self-launch
			set -l tmux_arg (string escape -- $tmux_arg)
			set -l tmux_arg "echo 'Launching qssh multipick pane $i ... ' && sleep $qssh_delay && $tmux_arg"
			set -l --prepend tmux_arg fish -il -C
			
			if [ $i -eq 1 ]
				if [ "$TMUX" = "" ]
					set -a tmux_arglist new-session
				else
					# already in tmux, open new window
					set -a tmux_arglist new-window
				end
			else
				if [ "$_flag_one_window" = "yes" ]
					set -a tmux_arglist split-window
				else
					set -a tmux_arglist new-window
				end
			end
			
			set -a tmux_arglist $tmux_arg \; 
			
			if [ "$_flag_one_window" = "yes" ]
				set -a tmux_arglist select-layout tiled \; 
			end
		end
		
		#set -a tmux_arglist \
		if [ "$_flag_one_window" = "yes" ]
			set -a tmux_arglist setw pane-border-format '#{pane_index} #T' \; \
				rename-window "qssh multipick" \; \
				setw allow-rename off \; setw automatic-rename off \; setw pane-border-status top \;
		end
		if [ "$_flag_mirror_keyboard" = "yes" ]
			set -a tmux_arglist setw synchronize-panes yes \; \
				setw pane-active-border-style bg=\#aaaa00,fg=\#000000 \; setw pane-border-style bg=\#aaaa00,fg=\#000000 \;
		end
		
		#setw window-style bg=\#330101,fg=\#ffffff \; setw window-active-style bg=\#330101,fg=\#ffffff \; \
		
		#echo tmux (string escape -- $tmux_arglist)
			
		#__qssh_pause
		tmux $tmux_arglist
		return $status
	end
	return 1
end

function __qssh_fingerprint --no-scope-shadowing
	ssh-keyscan -p $hostdef_port $hostdef_hostname > ~/.ssh/qssh-keyscan.tmp 2> /dev/null
	ssh-keygen -l -f ~/.ssh/qssh-keyscan.tmp | sort
	rm -f ~/.ssh/qssh-keyscan.tmp
end

function __qssh_remove_keys
	argparse 'R=' 'f=' -- $argv
	__qssh_echo_interactive -n "Removing host keys "
	if set -q _flag_f
		set opt_f -f $_flag_f
		__qssh_echo_interactive "from $_flag_f ..."
	else
		set -e opt_f
		__qssh_echo_interactive "..."
	end
	__qssh_echo_interactive -n  "$_flag_R"
	ssh-keygen -R "$_flag_R" $opt_f &> /dev/null
	set ipv4 (__qssh_resolve_ipv4 "$_flag_R")
	set ipv6 (__qssh_resolve_ipv6 "$_flag_R")
	if [ "$ipv4" != "" ]
		for i in $ipv4; __qssh_echo_interactive -n " $i"; ssh-keygen -R $i $opt_f &> /dev/null; end
	end
	if [ "$ipv6" != "" ]
		for i in $ipv6; __qssh_echo_interactive -n " $i"; ssh-keygen -R $i $opt_f &> /dev/null; end
	end
	__qssh_echo_interactive " ... done"
end

function __qssh_resolve -d \
	'resolves ip adresses from hostnames'
	argparse '#-ip46' -- $argv
	
	# test if input is ipv4
	if string match -q --regex -- '^([0-9]{1,3}\.){3}[0-9]{1,3}$' $argv
		echo $argv
		return 0
	end
	# test if input is ipv6
	if string match -q --regex -- '^[\:0-9a-f]+(([0-9]{1,3}\.){3}[0-9]{1,3})?(%.+)?$' $argv
		echo $argv
		return 0
	end
	
	if [ "$_flag_ip46" = "4" ]
		__qssh_resolve_ipv4 $argv
	else if [ "$_flag_ip46" = "6" ]
		__qssh_resolve_ipv6 $argv
	else
		if $__cap_getent
			getent hosts "$argv[1]" | cut -f 1 -d ' ' | sort | uniq
		else
			dscacheutil -q host -a name "$argv[1]" | string match "*_address:*" | string replace --regex -- '[^:]+: ' '' | sort | uniq
		end
	end
	return 0
end
function __qssh_resolve_ipv4
	if string match -q --regex -- '^([0-9]{1,3}\.){3}[0-9]{1,3}$' $argv
		echo $argv
		return 0
	end
	if $__cap_getent
		getent ahostsv4 "$argv[1]" | cut -f 1 -d ' ' | sort | uniq
	else
		dscacheutil -q host -a name "$argv[1]" | string match "ip_address:*" | string replace --regex -- '[^:]+: ' '' | sort | uniq
	end
	return 0
end
function __qssh_resolve_ipv6
	# test if input is ipv6
	if string match -q --regex -- '^[\:0-9a-f]+(([0-9]{1,3}\.){3}[0-9]{1,3})?(%.+)?$' $argv
		echo $argv
		return 0
	end
	if $__cap_getent
		getent ahostsv6 "$argv[1]" | cut -f 1 -d ' ' | sort | uniq
	else
		dscacheutil -q host -a name "$argv[1]" | string match "ipv6_address:*" | string replace --regex -- '[^:]+: ' '' | sort | uniq
	end
	return 0
end

function __qssh_clean_env -d \
	'Clean environment variables for subshells'
	# stop environmental pollution NOW!
	set -e __qssh_tmp_host_file
	set -e __qssh_db_mru_file
	set -e __qssh_db_autocomplete_cache_file
	set -e __qssh_db_skim_cache_file
	set -e __qssh_interval_compact_db
	set -e __qssh_countdown_compact_db
	set -e __qssh_controlpath_prefix
	set -e __qssh_default_user
	set -e __qssh_prompt_answer_tmp
	set -e __qssh_mru_pick_control_persist_checks
	set -e cnt_control_persist_checks
	set -e query
	# keep __qssh_nested
	
	# run callback
	$argv[1]
end

function __qssh_mc_sftp -d \
	'launches midnight commander as an sftp client, hooked to the persistant connection from qssh'
	set -l hostdef $argv
	if __qssh_parse_connect_args $hostdef
		# NOTE: sharing connection with mc requires
		# - sh, not sftp handler (sftp is better at aborting transfers, but it does not share connections)
		# - alias definiton in ~/.ssh/config
		
		# opening master connection beforehand so mc does not open a new connection
		# with incomplete arguments
		__qssh_mru_update $hostdef
		if ! __qssh_master_connect $hostdef
			echo "Error establishing master connection"
			__qssh_pause
			return 0
		end
		
		set -l ssh_alias qssh-$hostdef_user-$hostdef_hostname-$controlPathSuffix
		set -l ssh_regex_alias (string escape --style=regex -- ssh_alias)
		
		# craft a Host alias which will force mc to use either the existing
		# connection or fail. NOTE: this might cause 
		set -l ssh_config_tab \
"# START QSSH TMP $ssh_alias
# This will be deleted by qssh!
# Force mc to share existing connection with qssh
# $hostdef
Host $ssh_alias
	HostName nohost.invalid
	User invalid
	ControlPersist 1s
	ControlMaster no
	ControlPath $controlPath
# END QSSH TMP $ssh_alias"
		echo "$ssh_config_tab" >> ~/.ssh/config
		function __qssh_tmp_mc -V ssh_alias
			# blocking signals before changing variables
			block --local
			
			# NOTE: using fish as subshell causes strange delay here
			#  - forcing "dumb" bash as subshell
			set -q LC_NERDLEVEL
			and set -lx LC_NERDLEVEL 0
			set -lx SHELL /bin/bash
			
			mc ~ "sh://$ssh_alias"
		end
		__qssh_clean_env __qssh_tmp_mc
		functions -e __qssh_tmp_mc
		
		# strip alias from config
		echo -n "" > ~/.ssh/config.new
		set -l skip no
		for line in (cat ~/.ssh/config)
			if [ "$line" = "# START QSSH TMP $ssh_alias" ]
				set skip yes
				continue
			end
			if [ "$line" = "# END QSSH TMP $ssh_alias" ]
				set skip no
				continue
			end
			if [ "$skip" = "no" ]
				echo "$line" >> ~/.ssh/config.new
			end
		end
		
		rm -f ~/.ssh/config.bak
		mv ~/.ssh/config ~/.ssh/config.bak
		cat ~/.ssh/config.new > ~/.ssh/config # keeping permissions here
		rm -f ~/.ssh/config.new
		
		__qssh_db_mru_read mru $hostdef
		__qssh_cache_invalidate
		if [ "$mru_no_persist" = "yes" ]
			__qssh_exit $hostdef
		end
	end
end

function __qssh_new_scope -d \
	'just passes remaining argv to callback argv[1], providing an empty scope'
	set callback $argv[1]
	set -e argv[1]
	$callback $argv
	return $status
end

function __qssh_pause
	if [ "$argv" != "" ]
		read -P (set_color ff0)"$argv[1] - Press any key to continue ..."(set_color normal) -n1
	else
		read -P (set_color ff0)"Press any key to continue ..."(set_color normal) -n1
	end
end

function __qssh_prompt --no-scope-shadowing -d \
	'mostly pass thru to read, try handle ctrl-c'
		
		# grab the answer_varname from $argv
		set -l answer_varname
		set -l read_argv $argv
		begin
			# scope away the argparsers _flag values
			argparse 'c/command=' 'd/delimiter=' 'g/global' \
			's/silent' 'l/local' 'n/nchars=' 'p/prompt=' 'P/prompt-str=' \
			'R/right-prompt=' 'S/shell' 't/tokenize' 'u/unexport' \
			'U/universal' 'x/export' 'a/list' 'z/null' 'L/line' -- $argv
			if [ (count $argv) -ne 1 ]
				read -P "Error: unknown argv left over in '$argv'"
				return 1
			end
			set answer_varname $argv
		end
		
		# NOTE: signal trapping does not work due to an issue #6649 in fish
		# until it is resolved, this does not work.
		# function __qssh_abort_read --on-signal INT
		# 	functions -e __qssh_abort_read
		# 	set -g __qssh_read_aborted yes
		# 	__qssh_echo_interactive " ... abort by SIGINT, see Fish Issue #6649"
		# 	__qssh_pause
		# 	return 0
		# end
		
		# this workaround launches a subshell to capture ctrl-c at least for interactive mode
		if ! status is-interactive
			__qssh_echo_interactive "Warning: not interactive! Ctrl-c will abort execution! See Fish issue #6649"
		end
		set -l esc_read_argv (string escape -- $read_argv)
		fish -c "function fish_title; end; echo -ne '\e]2;qssh: ?\a'; read $esc_read_argv; echo (string escape -- \$$answer_varname) > \"$__qssh_prompt_answer_tmp\""
		or return 15
		if [ -e "$__qssh_prompt_answer_tmp" ]
			cat "$__qssh_prompt_answer_tmp" | read $read_argv
			rm "$__qssh_prompt_answer_tmp"
		else
			return 16
		end
		
		# echo 
		# echo (set_color $fish_color_autosuggestion)"(empty string to abort)"(set_color normal)
		# echo -en "\r\033[2A"
		# read $read_argv
		# or return 1
		
		#if [ "$$answer_varname" = "" ]
			#echo "Empty string ... aborted"
			#__qssh_pause
		#	return 1
		#end
		
		# attempting to work around issue #6649 by creating a subshell
		# not successful so far ...
		#fish -c 'read answer; echo $answer >&2' 2>| read -l myans
		
		# if set -q __qssh_read_aborted
		# 	set -ge __qssh_read_aborted
		# 	echo "! __qssh_read_aborted"
		# 	return 1
		# end
end

function __qssh_cache_update --argument do_wait
	if [ "$do_wait" = "--wait" ]
		# foreground cache update
		qssh --qssh-update-cache
	else
		# background cache update
		fish -c 'qssh --qssh-update-cache' &
		disown
	end
end

function __qssh_cache_valid --argument filename
	# NOTE: cache file is valid if it exists as we don't care about mru details in caches
	if [ -e "$filename" ]
		return 0
	else
		return 1
	end
end

function __qssh_cache_invalidate
	rm $__qssh_db_autocomplete_cache_file
	rm $__qssh_db_skim_cache_file
end

function __qssh_window_title_idle
	# trick status current-command into thinking "qssh" was
	# the most recent command run so fish_title works as expected.
	#qssh --qssh-noop && set -l window_title (fish_title qssh)
	# update window title
	#echo -ne "\e]0;$window_title\a"
	__qssh_echo_interactive -ne "\e]2;qssh<$hostname\a"
end

# function __qssh_window_title_input
# 	echo -ne "\e]2;qssh!\a"
# end

function __qssh_window_title_ssh
	__qssh_echo_interactive -ne "\e]2;qssh $argv<$hostname\a"
end

function __qssh_echo_interactive -d \
	'output meant for user to read'
	echo $argv 1>&2
end

# function __qssh_interruptable_sleep
# 	fish -c "sleep $argv"
# end
