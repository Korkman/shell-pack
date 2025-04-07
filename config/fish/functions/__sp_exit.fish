function __sp_exit
	if ! test (commandline | string collect) = ''
		commandline ''
	else if set -q __sp_fiddle_mode
		fiddle
	else if set -q VIRTUAL_ENV
		commandline 'venv'
		commandline --function execute
	else
		exit
	end
end
