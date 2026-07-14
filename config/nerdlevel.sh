#!/bin/sh

# source this file at the end of your POSIX shell .profile
# this will get you:
#  
# - the 'nerdlevel LEVEL' alias:
#   nerdlevel 1   # enter FISH without font support
#   nerdlevel 2   # enter FISH with powerline font support
#   nerdlevel 3   # enter FISH with nerd font support
# 
# - automatic transition to FISH when LC_NERDLEVEL is set:
#   set this variable in a terminal emulator profile to have it launch shell-pack.
#   also, many ssh daemons are setup to accept LC_* env vars (AcceptEnv). with
#   shell-pack installed server-side, you will stay in FISH once you enter it.

# nerdlevel > 0: upgrade to FISH shell
nerdlevel() {
	if [ "${MC_SID:-}" != "" ]; then
		# prevent launching inside midnight-commander - it has specific hooks
		# that break when one shell changes into another
		return
	fi
	
	if [ "$1" = "--help" ]; then
		echo "Enter or leave FISH shell with Shell-Pack, adjust symbol support"
		echo "  0 = return to \$OLDSHELL ($OLDSHELL)"
		echo "  1 = no symbols"
		echo "  2 = powerline font"
		echo "  3 = font awesome"
		return 1
	fi >&2
	
	export LC_NERDLEVEL="$1"
	if [ "${TMUX:-}" != "" ]; then
		echo "tmux note: new and existing windows will inherit new LC_NERDLEVEL"
		tmux set-env LC_NERDLEVEL "$1"
	fi
	if [ "$LC_NERDLEVEL" -gt 0 ] && command -v fish > /dev/null; then
		_nerdlevel_exec_fish
	fi
}

# internal function called when the current shell shall be replaced with fish
_nerdlevel_exec_fish() {
	# working around the workaround to get OSC133 support in konsole
	# see https://github.com/fish-shell/fish-shell/issues/12859
	# add omit-term-workarounds to fish_features if konsole is detected
	if [ "${KONSOLE_VERSION:-}" != "" ]; then
		case "${fish_features:-}" in
			*omit-term-workarounds*) ;;
			"") export fish_features=omit-term-workarounds ;;
			*)  export fish_features="${fish_features} omit-term-workarounds" ;;
		esac
	fi
	
	export OLDSHELL="$SHELL"
	SHELL=$(command -v fish)
	export SHELL
	exec fish -l
}

if [ "${MC_SID:-}" = "" ] && [ "${LC_NERDLEVEL:-0}" -gt 0 ] && command -v fish > /dev/null; then
	if [ "${BASH_VERSION:-}" != "" ]; then
		# exec in .bashrc fails with su + bash 5
		# workaround: run exec fish as prompt_command
		_nerdlevel_prompt_exec() {
			unset PROMPT_COMMAND
			unset PROMPT
			_nerdlevel_exec_fish
		}
		PROMPT_COMMAND=_nerdlevel_prompt_exec
		PROMPT=_nerdlevel_prompt_exec
		return
	else
		_nerdlevel_exec_fish
	fi
else
	export LC_NERDLEVEL=0
fi
