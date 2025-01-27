function __sp_keybinds \
	-d 'keybinds for shell-pack'
	
	# store modification time globally for automatic reload
	set -g __sp_keybinds_file (status --current-filename)
	set -g __sp_keybinds_mtime (__sp_getmtime "$__sp_keybinds_file")
	
	# NOTE: alt key does not work on juicessh at all - it is used to compose characters
	#       this might affect mac users as well.
	# NOTE2: ctrl bindings may hit control characters, as observed with ctrl-j and ctrl-h

	# ctrl-t to find file, alt-c to cd, ctrl-r to search history
	bind \ct skim-file-widget
	bind \cr skim-history-widget
	bind \ec skim-cd-widget

	if bind -M insert > /dev/null 2>&1
		bind -M insert \ct skim-file-widget
		bind -M insert \cr skim-history-widget
		bind -M insert \ec skim-cd-widget
	end

	# ctrl-f / alt-f to search in pager / search for files
	bind \cf 'quick_search --dotfiles'
	bind \ef 'quick_search --dotfiles'
	# ctrl-shift-* does not exist, using alt-shift-f instead
	bind \eF 'quick_search'

	# alt-up, ctrl-up, shift-up to cd ..
	bind \e\[1\;3A "quick_dir_up"
	bind \e\[1\;5A "quick_dir_up"
	# shift up in tmux
	bind \e\[1\;2A "quick_dir_up"

	# alt-down to cd one level, shift skips dotfiles
	bind \e\[1\;3B "skim-cd-widget-one --dotfiles"
	bind \e\[1\;4B "skim-cd-widget-one"
	# shift down in tmux
	bind \e\[1\;2B "skim-cd-widget-one --dotfiles"

	# alt-d skim_cdtagdir
	bind \ed 'skim-cdtagdir'

	# alt-x / alt-X for virt-manager console, juicessh, ...
	bind \ex "skim-cd-widget-one --dotfiles"
	bind \eX "skim-cd-widget-one"

	# re-assigning alt-left and alt-right to ignore commandline status (use ctrl-left and ctrl-right for word-wise cursor positioning!)
	bind \e\[1\;3D "quick_dir_prev"
	bind \e\[1\;3C "quick_dir_next"
	# shift-left and -right in tmux
	bind \e\[1\;2D "quick_dir_prev"
	bind \e\[1\;2C "quick_dir_next"

	# alt-y / alt-Y for virt-manager console
	bind \ey "quick_dir_prev"
	bind \eY "quick_dir_next"

	# alt-shift skips dotfiles
	bind \et "skim-file-widget --dotfiles"
	bind \eT "skim-file-widget"
	bind \ec "skim-cd-widget --dotfiles"
	bind \eC "skim-cd-widget"

	# alt-space for argument history search (copy alt-.)
	bind \e\x20 "history-token-search-backward"
	# alt-comma for argument history search forward (reverse alt-.)
	bind \e, "history-token-search-forward"

	#bind \cl "commandline -f repaint"

	# fast and visual grep using ripgrep and skim
	bind \cg "commandline --cursor 0; commandline --insert 'rrg '"
	bind \eg "commandline --cursor 0; commandline --insert 'rrg '"

	# reserved binds
	# DO NOT BIND CTRL-J, breaks mc, is newline escape seq (10th in alphabet = 0x10)
	# DO NOT BIND CTRL-H, breaks mc, is backspace escape seq (8th in alphabet = 0x8)

	# custom event: pressing enter emits custom event before fish_preexec
	bind \r "if ! commandline --paging-mode; emit sp_submit_commandline; end; commandline -f execute"
	# fill commandline with space so ctrl-c does something, also emit custom event before fish_cancel
	bind \cC "if test (commandline | string collect) = ''; commandline ' '; end; emit sp_cancel_commandline; commandline -f cancel-commandline"

	# bind Alt-Home to cd ~ | cd /
	bind \e\[1\;3H 'if test "$PWD" = "$HOME"; cd /; else; cd "$HOME"; end; commandline -f repaint'
	
	# alt-left and -right in linux console (kmscon)
	bind \e\e\[D "quick_dir_prev"
	bind \e\e\[C "quick_dir_next"
	# alt-down in linux console
	bind \e\e\[B "skim-cd-widget-one"
	# alt-up in linux console
	bind \e\e\[A "quick_dir_up"
	
	# if fish version is 4 (or higher)
	# yeah, we all hate version checks, but the keybinds have to be adjusted for 4.0
	if test (__sp_vercmp "$FISH_VERSION" "3.999.999") -gt 0
		# did something stupid? arrow-up to the command, hit f8 to delete
		bind f8 "__history_delete_commandline"
		# bind f10 to empty commandline, deactivate virtual env or exit - in this order of precedence
		bind f10 "if ! test (commandline | string collect) = ''; commandline ''; else if set -q VIRTUAL_ENV; commandline 'venv'; commandline --function execute; else; exit; end;"
		# bind f4 to history edit
		bind f4 '__sp_history_delete_and_edit_prev'
	else
		# did something stupid? arrow-up to the command, hit f8 to delete
		bind -k f8 "__history_delete_commandline"
		# bind f10 to empty commandline, deactivate virtual env or exit - in this order of precedence
		bind -k f10 "if ! test (commandline | string collect) = ''; commandline ''; else if set -q VIRTUAL_ENV; commandline 'venv'; commandline --function execute; else; exit; end;"
		# bind f4 to history edit
		bind -k f4 '__sp_history_delete_and_edit_prev'
		bind \e4 '__sp_history_delete_and_edit_prev'
	end
end
