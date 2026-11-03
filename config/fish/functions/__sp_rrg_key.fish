function __sp_rrg_key -d "Handle mode-specific rrg key actions."
	set -l rrg_navigation_keys 'p,v,e,h,q,space,+'
	set -l hide_input_action 'show-header+hide-input+change-prompt(> )+rebind('$rrg_navigation_keys')'
	switch "$argv[1]"
		case enter
			if test "$FZF_INPUT_STATE" = enabled
				echo "$hide_input_action"
			else
				echo 'execute(nullerror fishcall __sp_pager --line {2} {1})'
			end
		case escape
			if test -n "$FZF_QUERY"
				if test "$FZF_INPUT_STATE" = enabled
					echo clear-query
				else
					# fzf ignores clear-query while input is hidden, so reveal it like the space key does
					echo 'hide-header+show-input+change-prompt(Filter> )+clear-query+unbind('$rrg_navigation_keys')'
				end
			else
				if test "$FZF_INPUT_STATE" = enabled
					echo "$hide_input_action"
				else
					echo abort
				end
			end
		case '*'
			echo "Unknown rrg key action: $argv[1]" >&2
			return 2
	end
end
