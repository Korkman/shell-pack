function __sp_print_enhanced_prompt_exit_status --on-event fish_prompt --on-event fish_exit -d \
	"Print saved exit status line once, outside of OSC 133 markers for command output and prompt"
	if [ "$__display_cmd_stats" = "yes" ]
		for line in $__sp_enhanced_prompt_exit_status
			echo "$line"
		end
		set -e -g __display_cmd_stats
	end
end

