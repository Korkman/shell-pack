function __sp_grasp_oversized_choice -d \
"Decide how grasp's pager mode should handle input exceeding the memory limit."
	argparse 'editable' 's/size=' -- $argv
	or return 2

	set -l size $_flag_size
	set -l limit $argv[1]
	
	if set -q VISUAL
		set EDITOR $VISUAL
	end

	if test -r /dev/tty
		set -l size_human (__sp_bytes_human_readable $size)
		set -l memory_est_fzf_human (__sp_bytes_human_readable (math "$size * 5"))
		set -l limit_human (__sp_bytes_human_readable $limit)
		
		__sp_error (set_color --bold yellow)"ATTENTION:"(set_color normal)" Input is $size_human, exceeding the memory limit of $limit_human (GRASP_PAGER_MAX_SIZE)." > /dev/tty
		set -l lines
		set -a lines ""
		set -a lines "Open in:"
		if set -q _flag_editable
			set -a lines "  e) "(set_color $fish_color_command)"$EDITOR"(set_color normal)" "(set_color $fish_color_comment)"# default, ENTER"(set_color normal)
			set -a lines "  l) "(set_color $fish_color_command)"less"(set_color normal)
		else
			set -a lines "  e) "(set_color $fish_color_command)"$EDITOR"(set_color normal)" "(set_color $fish_color_param)"-"(set_color normal)" "(set_color $fish_color_comment)"# likely to consume memory (or /tmp)"(set_color normal)
			set -a lines "  l) "(set_color $fish_color_command)"less"(set_color normal)" "(set_color $fish_color_param)"-b … -B"(set_color normal)" "(set_color $fish_color_comment)"# default, limited scrollback, ENTER "(set_color normal)
		end
		set -a lines "  h) "(set_color $fish_color_command)"head"(set_color normal)" "(set_color $fish_color_param)"-c …"(set_color $fish_color_operator)" | "(set_color $fish_color_command)"fzf"(set_color normal)" "(set_color $fish_color_comment)"# pass $limit_human head to fzf"(set_color normal)
		set -a lines "  t) "(set_color $fish_color_command)"tail"(set_color normal)" "(set_color $fish_color_param)"-c …"(set_color $fish_color_operator)" | "(set_color $fish_color_command)"fzf"(set_color normal)" "(set_color $fish_color_comment)"# pass $limit_human tail to fzf"(set_color normal)
		set -a lines "  f) "(set_color $fish_color_command)"fzf"(set_color normal)" "(set_color $fish_color_comment)"# pass entire input to fzf (consumes about $memory_est_fzf_human memory)"(set_color normal)
		set -a lines "  q) quit"
		set -a lines ""
		set -a lines (set_color --bold)"Choice: "(set_color normal)
		for line in $lines
			echo $line
		end >&2
		
		set -l choice
		if read -n1 -P "" -l choice < /dev/tty >&2
			switch (string lower -- "$choice")
				case e
					echo editor
				case l
					echo less
				case f
					echo force
				case h
					echo fzf-head
				case t
					echo fzf-tail
				case q
					echo cancel
				case '*'
					# empty Enter takes the default; unrecognized input still cancels
					if test -z "$choice"
						if set -q _flag_editable
							echo editor
						else
							echo less
						end
					else
						echo cancel
					end
			end
		else
			# ctrl-c/EOF on the prompt cancels
			echo cancel
		end
	else if set -q _flag_editable
		# no controlling terminal to ask on: __sp_editor is fine for a file
		echo editor
	else
		# no controlling terminal to ask on: less is fine for a stream
		echo less
	end
end
