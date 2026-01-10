function __sp_autoupdate -e fish_prompt -e fish_focus_in -d \
	"Trigger autoupdate check after command execution"
	if test "$argv[1]" = "init"
		# just register as event handler
		return
	end
	
	# if not already pending, detect if config.fish has to be reloaded
	if test "$__reload_pending" != "yes"
		if test "$__sp_config_fish_file" = "" \
			|| test "$__sp_config_fish_md5" = "" \
			|| test (__sp_getmtime $__sp_config_fish_file) -ne $__sp_config_fish_mtime
			
			set -l new_md5 "invalid"
			if functions -q __sp_getmd5
				set new_md5 (__sp_getmd5 $__sp_config_fish_file)
			end

			if test "$new_md5" = "$__sp_config_fish_md5"
				# unchanged md5 - update timestamp, no reload necessary
				#echo "config.fish changed mtime, but md5 is equal, no action required"
				set -g __sp_config_fish_mtime (__sp_getmtime $__sp_config_fish_file)
			else
				# hint update
				set -g __reload_pending yes
			end
		end
	end
	
	# when no jobs are running, consider autoupdate
	if test "$__reload_pending" = "yes" \
		&& test "$__watched_job_pids" = "" -a "$disable_autoupdate" != "yes"
		
		# force a newline in case command output did not end with one
		echo
		# and output pending exit status line
		__sp_print_enhanced_prompt_exit_status
		
		# auto-update
		policeline "Reload: FISH config modified, environment reset"
		reload
	end
	
	# monitor tweaks file mtime, reload if changed
	if test "$__sp_tweak_env_mtime" != ""
		if test (__sp_getmtime $__sp_tweak_env_file) -ne $__sp_tweak_env_mtime
			source $__sp_tweak_env_file
			__sp_tweak_env
		end
	end
end
