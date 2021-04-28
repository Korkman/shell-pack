function skim-history-widget -d "Show command history"
	set -q SKIM_TMUX_HEIGHT; or set SKIM_TMUX_HEIGHT 40%
	begin
		set -lx SKIM_DEFAULT_OPTIONS "--height $SKIM_TMUX_HEIGHT $SKIM_DEFAULT_OPTIONS $SKIM_CTRL_R_OPTS -m"
		set -lx bind (string escape -- 'f8:execute[echo -n " history delete --exact --case-sensitive "(string escape -- {})" && history save"]+abort')
		history -z \
		| eval (__skimcmd) --read0 --print0 --no-multi --bind $bind --exact --tiebreak index \
		--header "'skim history. search for and select past cmd or esc to abort. f8 to delete.'" -q '(commandline)' \
		| read -zl result
		# NOTE: although nul delimited, read doesn't populate the list as intended
		# so, no multi delete yet
		#(count $result)
		commandline -- $result
	end
	commandline -f repaint
end
