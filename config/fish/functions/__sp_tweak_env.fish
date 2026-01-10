# NOTE: this file is actively monitored and reloaded automatically by fish_prompt.fish > __sp_autoupdate

function __sp_tweak_env -d \
	"shell-pack environment tweaks, repeatable for live patching"
	
	# detect os capabilities
	__sp_tweak_capabilities
	
	# add polyfills
	__sp_tweak_polyfills
	
	# store modification time globally for automatic reload
	set -g __sp_tweak_env_file (status --current-filename)
	set -g __sp_tweak_env_mtime (__sp_getmtime "$__sp_tweak_env_file")
	
	if ! set -q initial_env && $__cap_env_has_null
		# only Linux versions of "env" have --null
		# backup initial environment for reload
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
	end
	
	# treat TERM unknown to infocmp as xterm-256color, a compromise
	# for new terminal emulators which typically supercede xterm-256color
	# in relevant capabilities (xterm-kitty, foot, etc.)
	# note that installing respective terminfo packages is the better solution
	if command -q infocmp && ! infocmp &> /dev/null
		set -g __sp_trueterm "$TERM"
		# up to debian jessie, tmux was missing from terminfo database - we help by replacing it with xterm-256color
		if test "$TERM" = "tmux-256color" && infocmp screen-256color &> /dev/null
			set -gx TERM "screen-256color"
		else if test "$TERM" = "tmux" && infocmp screen &> /dev/null
			set -gx TERM "screen"
		else
			set -gx TERM "xterm-256color"
		end
	end
	
	# initialize theme
	__spt init

	# keybinds
	if ! set -q __sp_load_keybinds
		if status --is-interactive
			set __sp_load_keybinds "yes"
		end
	end
	if test "$__sp_load_keybinds" = "yes"
		__sp_tweak_keybinds
	end
	
	# apply live patches
	__sp_tweak_live_patches
	
	# misc tweaks
	__sp_tweak_user_defaults
	
	# init enhanced prompt status
	__sp_print_enhanced_prompt_exit_status init
	
	# list of environment variables to be kept in-sync within tmux sessions
	# these variables will be imported into the shell when attaching
	set -g __mmux_imported_environment \
		LC_NERDLEVEL \
		SHELL DISPLAY \
		XAUTHORITY \
		LANG \
		SSH_AUTH_SOCK \
		SSH_CLIENT \
		SSH_CONNECTION \
		SSH_TTY \
		SSH_AGENT_PID \
		SSH_ASKPASS \
		DBUS_SESSION_BUS_ADDRESS \
	;
	
	mmux --grab-hooks
end

function __sp_tweak_user_defaults -d \
	"Misc environment tweaks"
	# list of environment variables we fill here if not set by user
	set -l default_env_vars \
		EDITOR \
		VISUAL \
		PAGER \
		LESS_TERMCAP_so \
		LESS_TERMCAP_se \
		VIRTUAL_ENV_DISABLE_PROMPT \
	;
	
	# collect unset variables (user did not set them, we take control)
	# NOTE: this is cumulative until a reload happens
	set -q __sp_tweaked_env_vars
	or set -gx __sp_tweaked_env_vars
	for var in $default_env_vars
		if ! set -q $var
			# we need to export a space delimited list for subshells, so no `set -a` here
			set __sp_tweaked_env_vars (string trim -- "$__sp_tweaked_env_vars $var")
		end
	end
	
	for var in (string split ' ' -- $__sp_tweaked_env_vars)
		switch $var
			case EDITOR
				# default to mcedit for EDITOR if not set
				set -x -g EDITOR "mcedit"
			case VISUAL
				# same for VISUAL
				set -x -g VISUAL "mcedit"
			case PAGER
				# default pager setup
				set -x -g PAGER "less" "-FXRix4"
				if $__cap_less_has_mouse
					set -x -g PAGER "$PAGER --mouse"
				end
			case LESS_TERMCAP_so
				# bright yellow background in less highlights (improving manpage readability)
				set -x -g LESS_TERMCAP_so (set_color -b "ff0" && set_color "black")
			case LESS_TERMCAP_se
				set -x -g LESS_TERMCAP_se (set_color normal)
			case VIRTUAL_ENV_DISABLE_PROMPT
				# prompt already sports VIRTUAL_ENV support, disable activate.fish version
				set -g VIRTUAL_ENV_DISABLE_PROMPT yes
		end
	end
end

function __sp_tweak_polyfills -d \
	"Sets up polyfills for missing commands"
	
	# not a polyfill per se, but called often so it is placed here to reduce stat calls
	function __sp_getmtime -a file -d \
		'Get modification time of a file'
		if $__cap_ls_has_time_style
			set -l output (command ls -nl --time-style=+%s "$file" | string split --no-empty ' ')
			and echo "$output[6]"
		else if $__cap_stat_has_printf
			stat --printf '%Y' "$file"
		else
			stat -f %m "$file"
		end
	end

	# tac: reverse cat
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
end

function __sp_tweak_capabilities -d \
	"Populate capability variables"
	
	# detect OS capabilities (very rough)
	if [ (uname) = "Linux" ]
		set -g __cap_getent true

		set -g __cap_dscacheutil false
		set -g __cap_finger false
		set -g __cap_ss true
	else
		set -g __cap_getent false

		set -g __cap_dscacheutil true
		set -g __cap_finger true
		set -g __cap_ss false
	end

	# lazyloading capability variables
	# usage:
	#   if $__sp_cap_ls_has_time_style
	#   ...
	#   end
	set -g __cap_ls_has_time_style "__sp_cap_ls_has_time_style"
	set -g __cap_env_has_null "__sp_cap_env_has_null"
	set -g __cap_stat_has_printf "__sp_cap_stat_has_printf"
	set -g __cap_less_has_mouse "__sp_cap_less_has_mouse"
	set -g __cap_find_has_xtype "__sp_cap_find_has_xtype"
end

function __sp_tweak_keybinds \
	-d 'Load shell-pack keybinds and simple aliases'
	
	# NOTE: alt key does not work on juicessh at all - it is used to compose characters
	#       this might affect mac users as well.
	# NOTE2: ctrl bindings may hit control characters, as observed with ctrl-j and ctrl-h

	# ctrl-t to find file, alt-c to cd, ctrl-r to search history
	bind \ct skim-file-widget
	bind \cr skim-history-widget
	bind \ec skim-cd-widget

	if bind -M insert > /dev/null 2>&1
		bind -M insert \ct skim-file-widget
		bind -M insert \cr skim-history-widget
		bind -M insert \ec skim-cd-widget
	end

	# ctrl-f / alt-f to search in pager / search for files
	bind \cf 'quick_search --dotfiles'
	bind \ef 'quick_search --dotfiles'
	# ctrl-shift-* does not exist, using alt-shift-f instead
	bind \eF 'quick_search'

	# alt-up, ctrl-up, shift-up to cd ..
	bind \e\[1\;3A "quick_dir_up"
	bind \e\[1\;5A "quick_dir_up"
	# shift up in tmux
	bind \e\[1\;2A "quick_dir_up"

	# alt-down to cd one level, shift skips dotfiles
	bind \e\[1\;3B "skim-cd-widget-one --dotfiles"
	bind \e\[1\;4B "skim-cd-widget-one"
	# shift down in tmux
	bind \e\[1\;2B "skim-cd-widget-one --dotfiles"

	# alt-d skim_cdtagdir
	bind \ed 'skim-cdtagdir'

	# alt-x / alt-X for virt-manager console, juicessh, ...
	bind \ex "skim-cd-widget-one --dotfiles"
	bind \eX "skim-cd-widget-one"

	# shift-left and -right in tmux
	bind \e\[1\;2D "quick_dir_prev"
	bind \e\[1\;2C "quick_dir_next"

	# alt-y / alt-Y for virt-manager console
	bind \ey "quick_dir_prev"
	bind \eY "quick_dir_next"

	# alt-shift skips dotfiles
	bind \et "skim-file-widget --dotfiles"
	bind \eT "skim-file-widget"
	bind \ec "skim-cd-widget --dotfiles"
	bind \eC "skim-cd-widget"

	# alt-space for argument history search (copy alt-.)
	bind \e\x20 "history-token-search-backward"
	# alt-comma for argument history search forward (reverse alt-.)
	bind \e, "history-token-search-forward"

	#bind \cl "commandline -f repaint"

	# fast and visual grep using ripgrep and skim
	bind \cg "commandline --cursor 0; commandline --insert 'rrg '"
	bind \eg "commandline --cursor 0; commandline --insert 'rrg '"

	# reserved binds
	# DO NOT BIND CTRL-J, breaks mc, is newline escape seq (10th in alphabet = 0x10)
	# DO NOT BIND CTRL-H, breaks mc, is backspace escape seq (8th in alphabet = 0x8)

	# custom event: pressing enter emits custom event before fish_preexec
	bind \r "if ! commandline --paging-mode; emit sp_submit_commandline; end; commandline -f execute"
	# fill commandline with space so ctrl-c does something, also emit custom event before fish_cancel
	bind \cC "if test (commandline | string collect) = ''; commandline ' '; end; emit sp_cancel_commandline; commandline -f cancel-commandline"

	# bind Alt-Home to cd ~ | cd /
	bind \e\[1\;3H 'if test "$PWD" = "$HOME"; cd /; else; cd "$HOME"; end; commandline -f repaint'
	
	# keymap for kmscon
	# alt-left and -right in linux console
	bind \e\e\[D "prevd-or-backward-word"
	bind \e\e\[C "nextd-or-forward-word"
	# alt-down in linux console
	bind \e\e\[B "skim-cd-widget-one"
	# alt-up in linux console
	bind \e\e\[A "quick_dir_up"
	
	# if fish version is 4 (or higher)
	# yeah, we all hate version checks, but the keybinds have to be adjusted for 4.0
	if test (__sp_vercmp "$FISH_VERSION" "3.999.999") -gt 0
		# did something stupid? arrow-up to the command, hit f8 to delete
		bind f8 "__history_delete_commandline"
		# bind f10 to empty commandline, leave modes, exit - in this order of precedence
		bind f10 "__sp_exit"
		# bind f4 to history edit
		bind f4 '__sp_history_delete_and_edit_prev'
		bind f11 'fiddle --instant'
		bind f5 'echo; policeline "Reload: F5 key, environment reset"; reload'
	else
		# did something stupid? arrow-up to the command, hit f8 to delete
		bind -k f8 "__history_delete_commandline"
		# bind f10 to empty commandline, leave modes, exit - in this order of precedence
		bind -k f10 "__sp_exit"
		# bind f4 to history edit
		bind -k f4 '__sp_history_delete_and_edit_prev'
		bind \e4 '__sp_history_delete_and_edit_prev'
		bind -k f11 'fiddle --instant'
		bind -k f5 'echo; policeline "Reload: F5 key, environment reset"; reload'
	end
	
	# use d-tab to quickly navigate in tagged dirs
	alias d cdtagdir
	
	# screen / tmux shortcuts
	alias one "mmux one --exclusive \$argv"
	alias shareone "mmux one --exclusive --share \$argv"
	alias forceone "mmux one --exclusive --force \$argv"

	# set --universal __multiplexer_names to a list of tmux / screen session names
	set -q __multiplexer_names || set --universal __multiplexer_names pb rbeck
end

function __sp_tweak_live_patches -d \
	"Apply live patches to environment"
	# from time to time, upgraded shells can be live patched here until a config.fish
	# upgrade becomes necessary, at which point shells will reload with a policeline
	
	# remove deprecated variables
	set -e -g __sp_postexec_prompt_output
	if test "$LESS" = "-ix4" || test "$LESS" = "-ix4 --mouse"
		set -e -g LESS
	end
end