function __sp_load_shell_integrations -d \
	'Load shell integrations for enhanced terminal features'
	
	# force-load fish_prompt
	functions -q fish_prompt
	
	if string match -q "$TERM_PROGRAM" "vscode"
		# load vscode shell integration for VS Code's integrated terminal
		source $__sp_config_fish_dir/vscode_shell_integration.fish
	else
		# load iterm2 integration for everyone else
		source $__sp_config_fish_dir/iterm2_shell_integration.fish
	end
end
