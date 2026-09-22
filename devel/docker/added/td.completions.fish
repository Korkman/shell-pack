# Completion for the td function (see devel/docker/added/td.fish)

# force-load td.fish, which (as a side effect) also defines __sp_td_subcommands and all "td-*" functions
complete -c td -f -n '__fish_use_subcommand' -a '(functions -q td; __sp_td_subcommands)'

function __sp_td_version_tags
	test -d /repo/.git; or return 1
	git -C /repo tag --list
	echo worktree
end

function __sp_td_override_functions
	test -d /repo/.git; or return 1
	ls /repo/config/fish/functions/*.fish | string replace -ra '.*/([^/]+)\.fish' '$1'
end

complete -c td -f -n '__fish_seen_subcommand_from version' -a '(__sp_td_version_tags)'
complete -c td -f -n '__fish_seen_subcommand_from override' -a '(__sp_td_override_functions)'
