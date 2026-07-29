function mmux
	test "$argv" != ""
	and argparse -n mmux --exclusive 'f,s' --max-args 2 'e/exclusive' 'f/force' 's/share' 'n/nag' 'x-screen' 'g/grab-hooks' 'h/help' -- $argv
	and not set -q _flag_help
	or begin
		echo "\
Usage: mmux SOCKET_NAME [SESSION] [ --exclusive | --force | --share | --nag | --help ]

Attach to or create a screen / tmux session SESSION (default: SOCKET_NAME)
using socket SOCKET_NAME.

   -e/--exclusive     Limits session to one client and enables related messages.
                      If occupied, sends a message asking for access.
   -f/--force         Powerdetach other clients from SESSION.
   -s/--share         Attach to an otherwise exclusive SESSION, sending a message.
   -n/--nag           Nag the exclusive SESSION attached clients indefinitely.
   --screen           Force usage of screen instead of tmux
   --help             Show this help
"
		# --grab-hooks is used internally
		if set -q _flag_help
			return 0
		else
			return 2
		end
	end
	
	if set -q _flag_grab_hooks
	
		if set -q TMUX
			set -g __term_muxer "tmux"
		else if set -q STY
			set -g __term_muxer "screen"
		else
			set -g __term_muxer "none"
		end
		
		if ! set -q MC_SID
			# do not update environment inside mc
			function __mmux_tmux_update_shell_env --on-event fish_prompt --on-event fish_focus_in
				if set -q TMUX
					# inside TMUX, grab environment update with extra variables not imported
					set -l accept_env $__mmux_imported_environment __sp_tmux_ver 
					
					# skip variables that were locally modified outside of this routine,
					# so a manual local change is not silently overwritten again
					for masked in $__mmux_masked_environment
						set -l idx (contains -i -- $masked $accept_env)
						if set -q idx[1]
							set -e accept_env[$idx]
						end
					end
					
					set -l tmux_env (tmux show-environment 2> /dev/null)
					or return # tmux commands fail when env variable is set but not writable (su)
					
					# guard so __mmux_watch_* handlers can tell this update apart
					# from a local modification made by the user
					set -g __mmux_env_updating 1
					
					# update environment
					for v in $tmux_env
						if [ (string sub --start 1 --length 1 -- $v) = "-" ]
							# erase variables prefixed with minus which are currently set
							set -l vminus (string sub --start 2 -- $v)
							if contains -- $vminus $accept_env && set -q $vminus
								#echo "tmux: unset $vminus"
								set -ge $vminus
							end
						else
							# update changed variables
							set -l vsplit (string split --max 1 "=" -- $v)
							set -l vname "$vsplit[1]"
							set -l vval "$vsplit[2]"
							if contains -- $vname $accept_env
								# variable is on whitelist
								if ! set -q $vname
									# not currently set -> assume it is meant to be exported (SSH_AUTH_SOCK is)
									set -gx $vname $vval
								else if [ "$$vname" != "$vval" ]
									# value does not match, overwrite the global variable with the export flag kept as-is
									#echo "tmux: set $vname=$vval"
									if set --show "$vname" | string match --quiet --regex '.*: set in global scope, unexported.*'
										set -g $vname $vval
									else
										set -gx $vname $vval
									end
								end # if
							end # if
							
						end # if
					end # for
					
					set -e __mmux_env_updating
					
				end # if
			end # function
			
			# execute once right after execution so variable __sp_tmux_ver is immediately available
			__mmux_tmux_update_shell_env
			
			# watch imported environment variables for local modifications: if a
			# variable changes outside of __mmux_tmux_update_shell_env, assume the
			# user (or some other code) deliberately changed it locally and mask
			# it from future tmux-driven updates
			for v in $__mmux_imported_environment
				# except LC_NERDLEVEL, which synchronizes across all tmux windows on purpose
				if test "$v" = "LC_NERDLEVEL"
					continue
				end
				if not functions -q __mmux_watch_$v
					function __mmux_watch_$v --on-variable $v -V v
						if not set -q __mmux_env_updating
							if not contains -- $v $__mmux_masked_environment
								set -ga __mmux_masked_environment $v
							end
						end
					end
				end
			end
		end # if
		
		function __update_multiplexer_names --on-variable __multiplexer_names
			if set -q __defined_multiplexer_names
				for shortuser in $__defined_multiplexer_names
					functions -e $shortuser
				end
			end
			if set -q __multiplexer_names
				for shortuser in $__multiplexer_names
					if functions -q $shortuser
						__sp_error "Warning: \$__multiplexer_names conflicts with function $shortuser"
						continue
					end
					alias $shortuser "mmux $shortuser"
				end
			end
			set -g __defined_multiplexer_names $__multiplexer_names
		end
		__update_multiplexer_names
		
		return 0
	end
	
	# autoset exclusive flag
	if set -q _flag_force || set -q _flag_share || set -q _flag_nag
		set _flag_exclusive ""
	end
	set socket_name $argv[1]
	if set -q argv[2]
		set shortuser $argv[2]
	else
		set shortuser $socket_name
	end
	
	# backwards-compatibility: search for present sessions with the default socket name
	if test $socket_name != "default" && tmux -L default has-session -t $shortuser &> /dev/null
		set socket_name default
	end
	
	set have_screen (command -sq screen && echo true || echo false)
	set have_tmux (command -sq tmux && echo true || echo false)
	if set -q _flag_screen
		set have_tmux false
	end
	
	if set -q _flag_exclusive
		# exclusive attach to private session

		# smooth transition from old screen to new tmux: stay in screen unless exited
		if $have_screen && screen -list $shortuser > /dev/null
			set have_tmux false
		end
		if $have_tmux
			if tmux -L $socket_name has-session -t $shortuser &> /dev/null
				if [ (tmux -L $socket_name list-clients -t $shortuser | wc -l) -gt 0 ]
					if set -q _flag_force
						tmux -L $socket_name detach-client -P -s $shortuser
						__mmux_tmux_attach
					else if set -q _flag_share
						for client in (tmux -L $socket_name list-clients -t $shortuser | cut -d ':' -f 1)
							tmux -L $socket_name display-message -c $client 'Someone attached to your session!'
						end
						__mmux_tmux_attach
					else # no flag or nag
						while true
							for client in (tmux -L $socket_name list-clients -t $shortuser | cut -d ':' -f 1)
								tmux -L $socket_name display-message -c $client 'Another user wants to attach to this session!'
							end
							if not set -q _flag_nag
								break
							else
								sleep 1
								if [ (tmux -L $socket_name list-clients -t $shortuser | wc -l) -eq 0 ]
									__mmux_tmux_attach
									break
								end
								echo -n "."
							end
						end
						if not set -q _flag_nag
							echo 'Someone is attached to the exclusive session. A message was sent asking for access. Append --nag to keep sending the message in a loop.'
						end
					end # no flag or nag
				else # not list-clients
					__mmux_tmux_attach
				end # not list-clients
			else # not has-session
				echo 'Starting new session'
				__mmux_tmux_attach new
			end
		else if $have_screen
			if set -q _flag_force
				screen -D -R $shortuser
			else if set -q _flag_share
				screen -x $shortuser -X echo 'Someone attached to your screen!'
				screen -x $shortuser
			else
				screen -r $shortuser
				if [ $status -ne 0 ]
					while true
						screen -x $shortuser -X echo 'Another user wants to attach to this screen!'
						if [ $status -eq 0 ]
							if not set -q _flag_nag
								echo 'Someone is attached to the exclusive screen. A message was sent asking for access.'
							end
						else
							# screen does not exist yet
							screen -S $shortuser
						end
						if not set -q _flag_nag
							break
						else
							sleep 1
							echo -n "."
							if screen -r $shortuser > /dev/null
								break
							end # screen released
						end # if nag
					end # while
				end # screen was occupied
			end # no flag
		else
			__sp_error "No terminal multiplexer installed."
			return 1
		end
	else
		# normal shared attach to private tmux
		if $have_tmux && $have_screen && screen -list $shortuser > /dev/null
			# smooth transition from old screen to new tmux: connect to screen if running
			screen -x $shortuser
		else if $have_tmux
			if tmux -L $socket_name has-session -t $shortuser &> /dev/null
				__mmux_tmux_attach
			else
				__mmux_tmux_attach new
			end
		else if $have_screen
			screen -x $shortuser || screen -S $shortuser
		else
			__sp_error "No terminal multiplexer installed."
			return 1
		end
	end
end

function __mmux_tmux_attach --no-scope-shadowing -d \
	"When attaching tmux, update specific environment vars and reload .tmux.conf"
	if [ "$argv[1]" = "new" ]
		set tmuxverb new -s $shortuser
	else
		set tmuxverb attach -t $shortuser
	end
	# NOTE: this is backwards-compatible to Debian Stretch packaged tmux
	set -l tmux_update_environment
	set -l v
	for v in $__mmux_imported_environment
		if set -q $v
			set -a tmux_update_environment set-environment $v $$v \;
			set -a tmux_update_environment set-environment -g $v $$v \;
		else
			set -a tmux_update_environment set-environment -r $v \;
			set -a tmux_update_environment set-environment -g -r $v \;
		end
	end
	
	# attach, update env, auto-reload tmux.conf
	tmux -L $socket_name $tmuxverb \; \
		$tmux_update_environment \
		source-file ~/.tmux.conf
end

