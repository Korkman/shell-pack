# source this file at the end of your .profile
# then "nerdlevel [1-3]" or set LC_NERDLEVEL in your terminal

# nerdlevel > 0: upgrade to FISH shell
nerdlevel() {
	if [ "" != "$MC_SID" ]; then
		# prevent launching inside midnight-commander - it has specific hooks
		# that break when one shell changes into another
		return
	fi
	export LC_NERDLEVEL=$1
	if [ "" != "$TMUX" ]; then
		echo "tmux note: new and existing windows will inherit new LC_NERDLEVEL"
		tmux set-env LC_NERDLEVEL $1
	fi
	if [ "$LC_NERDLEVEL" -gt 0 ] && which fish > /dev/null; then
		export OLDSHELL=$SHELL
		export SHELL=$(which fish)
		exec fish -l
	fi
}

if [ "" = "$MC_SID" ] && [ "${LC_NERDLEVEL:-0}" -gt 0 ] && which fish > /dev/null; then
	if [ "${BASH_VERSION}" != "" ]; then
		# exec in .bashrc fails with su + bash 5
		# workaround: run exec fish as prompt_command
		function __run_fish() {
			export OLDSHELL=$SHELL
			export SHELL=$(which fish)
			unset PROMPT_COMMAND
			exec fish -l
		}
		export PROMPT_COMMAND=__run_fish
		export PROMPT=__run_fish
		return
	else
		export OLDSHELL=$SHELL
		export SHELL=$(which fish)
		exec fish -l
	fi
else
	export LC_NERDLEVEL=0
fi
