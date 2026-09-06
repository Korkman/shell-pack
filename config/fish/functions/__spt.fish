function __spt -d \
	"shell-pack theme - returns theme components like colors or glyphs" -a component -a variant
	# __spt init
	if test "$component" = "init"
		__spt_init
		return
	end
	
	set -l scolor "set_color"
	if test "$variant" = "bg"
		set scolor "set_color" "-b"
	end
	if test "$variant" = "bold"
		set scolor "set_color" "--bold"
	end
	
	# colors
	switch $component
		case status_ok
			$scolor "0b0"
			return
		case status_fail
			$scolor "c00"
			return
		case cmd_ok_bg pid_bg
			if test $__cap_colors -ge 256
				$scolor "171"
			else
				$scolor "green"
			end
			return
		case cmd_ok_fg pid_fg
			if test $__cap_colors -ge 256
				$scolor "fff"
			else
				$scolor black
			end
			return
		case cmd_fail_bg
			$scolor "711"
			return
		case cmd_fail_fg
			$scolor "fff"
			return
		case warning_bg
			$scolor "711"
			return
		case warning_fg
			$scolor "ff0"
			return
		case jobs_fg
			$scolor black
			return
		case jobs_bg
			if test $__cap_colors -ge 256
				$scolor "dd0"
			else
				$scolor bryellow
			end
			return
		case chroot_bg
			$scolor "000"
			return
		case chroot_fg
			$scolor "fff"
			return
		case venv_bg
			$scolor "3a3a3a"
			return
		case venv_fg
			$scolor "ff0"
			return
		case tag_bg
			$scolor "ff0"
			return
		case tag_fg
			$scolor "000"
			return
		case confidential_bg
			$scolor "purple"
			return
		case confidential_fg
			$scolor "fff"
			return
		case fiddle_bg
			$scolor "070"
			return
		case fiddle_fg
			$scolor "fff"
			return
		case pwd_bg fzf_prompt_bg
			$scolor "3a3a3a"
			return
		case pwd_fg fzf_prompt_fg
			$scolor "fff"
			return
		case fzf_title
			$scolor "fff"
			return
		case pwd_fg_dim
			$scolor "bbb"
			return
		case pwd_fg_dim_sep
			$scolor "888"
			return
		case bookmark_bg
			if test $__cap_colors -ge 256
				$scolor "007292"
			else
				$scolor "cyan"
			end
			return
		case bookmark_fg
			if test $__cap_colors -ge 256
				$scolor "fff"
			else
				$scolor "black"
			end
			return
		case readonly_bg
			$scolor "711"
			return
		case readonly_fg
			$scolor "fff"
			return
		case deleted_fg
			$scolor "b22"
			return
		case user_root_bg
			$scolor "711"
			return
		case user_root_fg
			$scolor "fff"
			return
		case user_normal_bg
			if test $__cap_colors -ge 256
				$scolor "707070"
			else
				$scolor black
			end
			return
		case user_normal_fg
			$scolor "fff"
			return
		case shlvl_bg
			$scolor "3a3a3a"
			return
		case shlvl_fg
			$scolor "ff0"
			return
		case policeline_fg
			$scolor "ff0"
			return
		case policeline_text
			$scolor "fff"
			return
		case prompt_fg
			$scolor "ff0"
			return
		case fish_command_fg linenumber
			$scolor "00ff87"
			return
		case fish_command_color
			echo -n "00ff87"
			return
		case unavailable_option
			$scolor --dim --strikethrough
			return
		case link
			$scolor --underline "00afff"
			return
		case fish_comment_color
			echo -n "d1b5ff"
			return
		case fish_autosuggestion_color
			if test $__cap_colors -ge 256
				echo -n "9e9e9e"
			else
				echo -n "white"
			end
			return
	end

	# glyphs
	if test "$theme_powerline_fonts" = "no"
		switch $component
			case right_black_arrow
				echo ''
				return
			case left_black_arrow
				echo ''
				return
		end
	end

	if test "$theme_nerd_fonts" = "no"
		switch $component
			case happy
				echo ':-)'
				return
			case unhappy
				echo ':-('
				return
			case running
				echo 'jobs'
				return
			case lock
				echo '!ro'
				return
			case lowspace
				echo '!df'
				return
			case tag
				echo '#'
				return
			case white_black_forward_block
				echo '█'
				return
			case black_white_forward_block
				echo ' '
				return
			case white_black_backward_block
				echo '█'
				return
			case black_white_backward_block
				echo ' '
				return
			case bookmark
				echo ''
				return
			case home
				echo '~'
				return
			case deleted
				echo 'X'
				return
			case confidential
				echo '!'
				return
			case fiddle
				echo 'fiddle'
				return
			case duration
				echo '  '
				return
			case calendar
				echo ' '
				return
			case clock
				echo ' '
				return
			case warnsign
				echo '! '
				return
			case nfsymspace
				# a space, but only if nf symbols are used
				echo ''
				return
		end
	end

	switch $component
		case right_arrow
			echo ''
			return
		case left_arrow
			echo ''
			return
		case right_black_arrow
			echo ''
			return
		case left_black_arrow
			echo ''
			return
		case happy
			echo ''
			return
		case unhappy
			echo ''
			return
		case running
			echo ''
			return
		case lock
			echo ''
			return
		case lowspace
			echo '󱘺'
			return
		case bookmark
			echo ' '
			return
		case tag
			echo ' '
			return
		case white_black_forward_block
			echo ''
			return
		case black_white_forward_block
			echo ''
			return
		case white_black_backward_block
			echo ''
			return
		case black_white_backward_block
			echo ''
			return
		case home
			echo '󰋞'
			return
		case deleted
			echo ''
			return
		case confidential
			echo '󰗹'
			return
		case fiddle
			echo 'fiddle '
			return
		case duration
			echo '  '
			return
		case calendar
			echo ' '
			return
		case clock
			echo ' '
			return
		case warnsign
			echo ' '
			return
		case nfsymspace
			# a space, but only if nf symbols are used
			echo ' '
			return
		case '*'
			echo "Unknown component: $component" >&2
			return 1
	end
end

function __spt_init -d \
	'Initialize shell-pack theme variables'
	# POWERLINE / NERD FONTS

	# check LC_NERDLEVEL (custom variable passing through default sshd_config)
	# activate powerline fonts only if set to 1 or higher

	set -q LC_NERDLEVEL
	or set -gx LC_NERDLEVEL 1

	function __update_nerdlevel --on-variable LC_NERDLEVEL
		# nerdlevel 1: bashrc launches fish
		
		set -g theme_greeting_add ""
		
		# not a number? fix.
		if ! string match -qr -- "[0-9]+" "$LC_NERDLEVEL"
			set -g LC_NERDLEVEL 1
			return
		end
		
		# nerdlevel 2: powerline font installed
		if test "$LC_NERDLEVEL" -gt 1
			set -g theme_powerline_fonts yes
		else
			set -g theme_powerline_fonts no
		end

		# nerdlevel 3: nerdfont installed
		if test "$LC_NERDLEVEL" -gt 2
			set -g theme_nerd_fonts yes
		else
			set -g theme_nerd_fonts no
		end
	end

	__update_nerdlevel

	if ! set -q __cap_colors
		__spt_track_term
	end

	set -g fish_prompt_pwd_dir_length 0
	set -g theme_time_format "+%H:%M:%S"           # time format for time hints
	set -g theme_date_format "+%Y-%m-%d"           # date format for date hints
	
	# full fish theme override to ensure nothing clashes
	# unused colors commented out
	set -g fish_color_autosuggestion (__spt fish_autosuggestion_color)
	set -eg fish_color_builtin
	set -g fish_color_cancel '-r'
	set -g fish_color_command (__spt fish_command_color)
	set -g fish_color_comment (__spt fish_comment_color)
	#set -g fish_color_cwd 'green'
	#set -g fish_color_cwd_root 'red'
	set -g fish_color_end '009900'
	set -g fish_color_error 'ff0000'
	set -g fish_color_escape '00a6b2'
	set -eg fish_color_function
	set -g fish_color_history_current '--bold'
	#set -g fish_color_host 'normal'
	#set -g fish_color_host_remote 'yellow'
	set -eg fish_color_keyword
	set -g fish_color_match '--background=brblue'
	set -g fish_color_normal 'normal'
	set -g fish_color_operator '00a6b2'
	set -eg fish_color_option
	set -g fish_color_param '00afff'
	set -g fish_color_quote 'ffaf00'
	set -g fish_color_redirection '00afff'
	set -g fish_color_search_match 'white --background=brblack'
	set -g fish_color_selection 'white --bold --background=brblack'
	#set -g fish_color_status 'red'
	#set -g fish_color_user 'brgreen'
	set -g fish_color_valid_path '--underline'
	
	set -g fish_pager_color_description $fish_color_quote '--italics'
	set -g fish_pager_color_prefix '--underline'
	set -g fish_pager_color_progress '000000' "--background=$fish_color_command"
	set -g fish_pager_color_selected_background '-r'
end

function __spt_track_term -v TERM
	if type -q tput
		and set -l colors (tput colors 2>/dev/null)
		set -gx __cap_colors $colors
	else if string match -q -- "*-256color" "$TERM"
		set -gx __cap_colors 256
	else
		set -gx __cap_colors 8
	end
end
