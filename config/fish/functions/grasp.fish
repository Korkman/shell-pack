function grasp -d \
	"Pipe live stream or file through fzf"
	
	argparse t/tail=? -- $argv
	if set -q _flag_tail
		set GRASP_TAIL $_flag_tail
	else if not set -q GRASP_TAIL
		set GRASP_TAIL 10000
	end
	
	if test (count $argv) -eq 0
		if set -q __saved_cmdline
			set desc_input (__spt prompt_fg)(string replace --regex "\|.*grasp.*" "" -- "$__saved_cmdline")(set_color normal)
		else
			set desc_input "STDIN"
		end
	else if test (count $argv) -eq 1
		set desc_input $argv[1]
	else
		echo "Usage: grasp [FILE]" >&2
		echo "       cat FILE | grasp" >&2
		return 1
	end
	set -l fzf_header ""
	__sp_fzf_defaults "grasping $desc_input"
	set -a fzf_defaults --tac --tail=$GRASP_TAIL --no-reverse --wrap
	set -p fzf_defaults fzf
	if set -q argv[1]
		tail -n $GRASP_TAIL -- $argv[1] | $fzf_defaults
	else
		$fzf_defaults
	end
end
