function td-ggit -d \
	"Create a Git test repository"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td ggit"
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	mkdir -p "$HOME/ggit-test"
	cd "$HOME/ggit-test"; or return 1
	git init -q
	git config --global user.email 'you@example.com'
	git config --global user.name 'Your Name'
	printf 'New file\n' > newfile.txt
end
