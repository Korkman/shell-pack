function reload -d "Reset environment (mostly)"
	# reload function
	# - backups up initial environment
	# - resets environment to backup
	# - replaces running process with new fish instance
	if $__cap_env_has_null and set -q initial_env
		if ! isatty 1
			if test -w /dev/tty
				policeline "Reload: STDOUT is not a terminal, failing" > /dev/tty
			end
			return 2
		end
		
		if set -q MC_SID
			# TODO: new instance needs to:
			# - copy over fish_prompt and fish_prompt_mc
			# - erase fish_right_prompt
			echo "Cannot reload within midnight commander"
			return 1
		end
		# pass thru these specific variables
		if [ "disable_autoupdate" = "yes" ]
			set -g initial_env $initial_env disable_autoupdate=$disable_autoupdate
		end
		if set -q __session_tag
			set -g initial_env $initial_env __session_tag=$__session_tag
		end
		if set -q fish_private_mode
			set -g initial_env $initial_env fish_private_mode=$fish_private_mode
		end
		if set -q fish_history
			set -g initial_env $initial_env fish_history=$fish_history
		end
		# merge and pass fish_features flags
		set -l pass_fish_features (string split ',' -- $fish_features)
		if set -q __sp_reload_fish_features
			set -a pass_fish_features $__sp_reload_fish_features
		end
		if set -q pass_fish_features
			set pass_fish_features (string join ',' -- $pass_fish_features)
			set -g initial_env $initial_env fish_features=$pass_fish_features
		end
		# escape all list entries for use in eval, replace custom escape sequence with newline escape sequence
		set -g initial_env (string escape -- $initial_env | string replace --all "putAfreakinNewlineHere342273" "\\n")
		set fish_binary (status fish-path)
		if ! test -e "$fish_binary"
			# good luck (fish path changed, let env find it)
			set fish_binary "fish"
		end
		
		# create a function using eval to execute the pre-escaped string as-is
		eval function the_end \n exec env --ignore-environment $initial_env $fish_binary -l \n end
		# emit fish_exit event and give time to reap exit status of children to prevent zombies
		emit "fish_exit"
		sleep 1
		# run the function
		the_end
		#exec env fish -l # NOTE: this locks up midnight commander!
	else
		# cheap reload function for other OS
		if set -q MC_SID
			# TODO: new instance needs to:
			# - copy over fish_prompt and fish_prompt_mc
			# - erase fish_right_prompt
			echo "Cannot reload within midnight commander"
			return 1
		end
		# emit fish_exit event and give time to reap exit status of children to prevent zombies
		emit "fish_exit"
		sleep 1
		exec env fish -l
	end
end
