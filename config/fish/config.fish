# main config.fish

# load main config only when interactive
if ! set -q __sp_load
	if status --is-interactive
		set __sp_load "yes"
	end
end
if ! set -q __sp_load_keybinds
	if status --is-interactive
		set __sp_load_keybinds "yes"
	end
end

function load_shell_pack -d "Load shell-pack"

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

	# detect OS capabilities (very rough)
	if [ (uname) = "Linux" ]
		set -g __cap_env_has_null true
		set -g __cap_stat_has_printf true
		set -g __cap_getent true

		set -g __cap_dscacheutil false
		set -g __cap_finger false
		set -g __cap_ss true
	else
		set -g __cap_env_has_null false
		set -g __cap_stat_has_printf false
		set -g __cap_getent false

		set -g __cap_dscacheutil true
		set -g __cap_finger true
		set -g __cap_ss false
	end

	# reload function
	# - backups up initial environment
	# - resets environment to backup
	# - replaces running process with new fish instance
	if $__cap_env_has_null
		# only Linux versions of "env" have --null
		# backup initial environment
		set -g initial_env (\
			# env: switch to NUL delimited output so we can work with newline values
			env --null | \
			# sed: replace newlines with custom escape sequence
			sed ':a;N;$!ba;s/\n/putAfreakinNewlineHere342273/g' | \
			# sed: replace NUL bytes with newlines, making initial_env a list
			sed 's/\\o0/\n/g' \
		)
		# decrease SHLVL to offset the increment which already happened
		set -g initial_env $initial_env SHLVL=(math $SHLVL - 1)
		function reload -d "Reset environment (mostly)"
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
			# escape all list entries for use in eval, replace custom escape sequence with newline escape sequence
			set -g initial_env (string escape -- $initial_env | string replace --all "putAfreakinNewlineHere342273" "\\n")
			# create a function using eval to execute the pre-escaped string as-is
			eval function the_end \n exec env --ignore-environment $initial_env fish -l \n end
			# emit fish_exit event and give time to reap exit status of children to prevent zombies
			emit "fish_exit"
			sleep 1
			# run the function
			the_end
			#exec env fish -l # NOTE: this locks up midnight commander!
		end
	else
		# cheap reload function for other OS
		function reload -d "Reset environment (mostly)"
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

	# polyfills
	if ! command -sq tac
		function tac
			tail -r -- $argv
		end
	end
	
	# test if the command 'kill' is available. if not, improvise!
	# mc fish_prompt issues 'kill -STOP %self' to give control back to mc
	# since kill is not a builtin (yet), we depend on it here to be a command
	# this can happen in docker images or similar minimalistic containers.
	# mc will hang whatever we do, so this polyfill will kill using the hopefully
	# built-in of another installed shell ...
	if ! command -q kill and ! builtin -q kill
		function kill -d "Kill polyfill for mc subshell - see fish_prompt.fish"
			/usr/bin/env sh -c "kill $argv"
		end
	end

	# these functions are possibly called many times a second, so they are not put in dedicated function files
	function __sp_getmtime -a file -d \
		'Get modification time of a file'
		if $__cap_stat_has_printf
			stat --printf '%Y' "$file"
		else
			stat -f %m "$file"
		end
	end

	function __sp_sigusr1 -s SIGUSR1
		# only a placeholder to guarantee the signal is handled,
		# not killing us when no handler is present (reload & timer pulse race precaution)
	end
 
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

	set -g __sp_config_fish_mtime (__sp_getmtime $__sp_config_fish_file)
	set -g __sp_config_fish_md5 (__sp_getmd5 $__sp_config_fish_file)

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

	# POWERLINE / NERD FONTS

	# check LC_NERDLEVEL (custom variable passing through default sshd_config)
	# activate powerline fonts only if set to 1 or higher

	set -q LC_NERDLEVEL
	or set -gx LC_NERDLEVEL 1

	function __update_nerdlevel --on-variable LC_NERDLEVEL
		# nerdlevel 1: bashrc launches fish
		
		set -g theme_greeting_add ""
		
		# nerdlevel 2: powerline font installed
		if test $LC_NERDLEVEL -gt 1
			set -g theme_powerline_fonts yes
		else
			set -g theme_powerline_fonts no
		end

		# nerdlevel 3: nerdfont installed
		if test $LC_NERDLEVEL -gt 2
			set -g theme_nerd_fonts yes
		else
			set -g theme_nerd_fonts no
		end
	end

	__update_nerdlevel
	
	# list of environment variables to be kept in-sync within tmux sessions
	set -g __mmux_imported_environment \
	LC_NERDLEVEL SHELL DISPLAY XAUTHORITY LANG SSH_AUTH_SOCK SSH_CLIENT \
	SSH_CONNECTION SSH_TTY SSH_AGENT_PID SSH_ASKPASS DBUS_SESSION_BUS_ADDRESS

	mmux --grab-hooks

	# detect and coordinate advanced shell integration loading (if not in mc subshell, not a dumb terminal, etc.)
	if test "$MC_SID" = ""; and test "$TERM" != "dumb"; and test "$TERM" != "linux"; and status --is-interactive
		# load fish_prompt
		fish_prompt > /dev/null
		
		if string match -q "$TERM_PROGRAM" "vscode"
			# load vscode shell integration for VS Code's integrated terminal
			source $__sp_config_fish_dir/vscode_shell_integration.fish
		else
			# load iterm2 integration for everyone else
			source $__sp_config_fish_dir/iterm2_shell_integration.fish
		end
	end

	# bright yellow background in less highlights (improving manpage readability)
	if ! set -x -q LESS_TERMCAP_so
		set -x -g LESS_TERMCAP_so (set_color -b "ff0" && set_color "black")
	end
	if ! set -x -q LESS_TERMCAP_se
		set -x -g LESS_TERMCAP_se (set_color normal)
	end

	# prompt already sports VIRTUAL_ENV support, disable activate.fish version
	if ! set -q VIRTUAL_ENV_DISABLE_PROMPT
		set -g VIRTUAL_ENV_DISABLE_PROMPT yes
	end
	
	if [ "$__sp_load_keybinds" = "yes" ]
		__sp_keybinds
	end
	
	# use d-tab to quickly navigate in tagged dirs
	alias d cdtagdir

	# actual preferences

	set -g fish_prompt_pwd_dir_length 0
	set -g theme_time_format "+%H:%M:%S"           # time format for time hints
	set -g theme_date_format "+%Y-%m-%d"           # date format for date hints

	set -g fish_color_command '00ff87'
	set -g fish_color_autosuggestion '9e9e9e'
	
	# this will be unset on pre-exec
	set -g __right_prompt_pid_once ""

	# screen / tmux shortcuts
	alias one "mmux one --exclusive \$argv"
	alias shareone "mmux one --exclusive --share \$argv"
	alias forceone "mmux one --exclusive --force \$argv"

	# set --universal __multiplexer_names to a list of tmux / screen session names
	set -q __multiplexer_names || set --universal __multiplexer_names pb rbeck
end

if [ "$__sp_load" = "yes" ]
	load_shell_pack
end
