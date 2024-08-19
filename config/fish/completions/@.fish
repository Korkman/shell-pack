complete --command @ -f -n 'test (__fish_number_of_cmd_args_wo_opts) -lt 2' -a "12:00 'tue 01:00' '1 hour' '10 seconds'" -d "Specify when in the future the commandline shall run"
complete --command @ -f -n 'test (__fish_number_of_cmd_args_wo_opts) -ge 2' -d "Command to run" -xa '(__fish_complete_subcommand --fcs-skip=2)'
