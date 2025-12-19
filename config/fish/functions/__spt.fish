function __spt -d "shell-pack theme - returns theme components like colors or glyphs" -a component -a variant
	set -l scolor "set_color"
	if test "$variant" = "bg"
		set scolor "set_color" "-b"
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
		case warning_bg
			$scolor "eee"
			return
		case warning_fg
			$scolor "f00"
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
		case pwd_bg
			$scolor "3a3a3a"
			return
		case pwd_fg
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
		case fish_command
			echo -n "00ff87"
			return
		case fish_autosuggestion
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
			case tag
				echo '#'
				return
			case white_black_forward_block
				echo '██'
				return
			case black_white_forward_block
				echo '  '
				return
			case white_black_backward_block
				echo '██'
				return
			case black_white_backward_block
				echo '  '
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
		case *
			echo "Unknown component: $component" >&2
			return 1
	end
end


set -g __cap_colors (tput colors) || begin
	# if tput fails, fix $TERM and retry
	if test "$TERM" = "tmux-256color"
		set -g TERM "screen-256color"
	else if test "$TERM" = "tmux"
		set -g TERM "screen"
	else
		set -g TERM "linux"
	end
	set -g __cap_colors (TERM=$TERM tput colors)
end
set -g fish_color_command (__spt fish_command)
set -g fish_color_autosuggestion (__spt fish_autosuggestion)

