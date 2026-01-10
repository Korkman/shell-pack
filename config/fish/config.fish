# main config.fish

# load main config only when interactive
if ! set -q __sp_load
	if status --is-interactive
		set __sp_load "yes"
	end
end

function load_shell_pack -d "Load shell-pack"
	# determine important paths early
	set -g __sp_config_fish_file (status --current-filename)
	set -g __sp_config_fish_dir (string replace --regex -- '/[^/]*$' '' $__sp_config_fish_file)
	set -g __sp_config_dir (string replace --regex -- '/[^/]*$' '' $__sp_config_fish_dir)
	set -g __sp_dir (string replace --regex -- '/[^/]*$' '' $__sp_config_dir)

	# NOTE: as many distros come with pre-existing fish prompts, we override by *prepending*
	if ! contains -- "$__sp_config_fish_dir/functions" $fish_function_path
		set -g --prepend fish_function_path "$__sp_config_fish_dir/functions"
	end
	if ! contains -- "$__sp_config_fish_dir/completions" $fish_complete_path
		set -g --prepend fish_complete_path "$__sp_config_fish_dir/completions"
	end
	# unqoted path is converted to space separated list, compatible to contains
	if ! contains -- "$__sp_dir/bin" $PATH
		set -g --prepend PATH "$__sp_dir/bin"
	end
	# this is only available as of fish 3.2
	#fish_add_path --path --global --prepend -- "$__sp_dir/bin"

	# unexport variables meant only for reload
	if set -q disable_autoupdate
		set -gu disable_autoupdate $disable_autoupdate
	end
	if set -q __session_tag
		set -gu __session_tag $__session_tag
	end

	# disable autoupdate in mc subshell until transfer of patched 
	# fish_prompt & fish_prompt_mc is implemented
	if set -q MC_SID
		set -g disable_autoupdate yes
	end
	
	# tweak environment
	# - polyfills
	# - $__cap_* capabilities
	# - default EDITOR, PAGER, TERM, etc.
	# - keybinds
	__sp_tweak_env
	
	# hash and mtime of config.fish for auto reload
	set -g __sp_config_fish_mtime (__sp_getmtime $__sp_config_fish_file)
	set -g __sp_config_fish_md5 (__sp_getmd5 $__sp_config_fish_file)
	
	# initialize __sp_autoupdate
	__sp_autoupdate init
	
	# provide $short_hostname globally
	set -g short_hostname (echo "$hostname" | string replace --regex '\..*' '')

	# normalize starting fish -l without nerdlevel.sh
	# all subshells should be fish from here
	set -gx SHELL (status fish-path)
	# fill-in $OLDSHELL with information from getent / passwd
	if test "$OLDSHELL" = ""
		if $__cap_getent
			# for Linux
			set -g OLDSHELL (getent passwd $USER | cut -f 7 -d ":")
		else if $__cap_finger
			# for macOS
			set -g OLDSHELL (finger $USER | grep 'Shell:*' | cut -f3 -d ":" | string trim)
		else
			# for others
			set -g OLDSHELL (grep -E "^$USER:" < /etc/passwd | cut -f 7 -d ":")
		end
	end
	if test "$OLDSHELL" = "$SHELL" || test "$OLDSHELL" = ""
		# so the user has chsh to fish, what is oldshell supposed to do?
		# or the passwd shell was not found
		# test if bash, zsh, tcsh is available, use that as "oldshell"
		if command -q bash
			set -g OLDSHELL (command -s bash)
		else if command -q zsh
			set -g OLDSHELL (command -s zsh)
		else if command -q tcsh
			set -g OLDSHELL (command -s tcsh)
		end
	end
	
	# detect and coordinate advanced shell integration loading (if not in mc subshell, not a dumb terminal, etc.)
	if test "$MC_SID" = ""; and test "$TERM" != "dumb"; and test "$TERM" != "linux"; and status --is-interactive
		__sp_load_shell_integrations
	end

	# have the right prompt show pid and shlvl once
	set -g __right_prompt_pid_once ""
end

if [ "$__sp_load" = "yes" ]
	load_shell_pack
end
