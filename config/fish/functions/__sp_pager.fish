function __sp_pager -d \
	'Invoke the configured pager'
	if set -gq $PAGER
		$PAGER $argv
	else
		less $argv
	end
end