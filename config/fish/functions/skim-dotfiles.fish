function skim-dotfiles -S
	if [ "$argv[1]" = "yes" ]
		set SKIM_DOTFILES_FILTER " -false "
	else
		set SKIM_DOTFILES_FILTER " -path \$dir'*/\\.*' "
	# switched to -xdev instead of " -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' "
	end
end
