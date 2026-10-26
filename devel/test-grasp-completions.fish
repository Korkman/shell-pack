#!/usr/bin/env fish
# Run with: fish --no-config devel/test-grasp-completions.fish
set -l repo (dirname (status filename))/..
source "$repo/config/fish/completions/grasp.fish"
source "$repo/config/fish/completions/ppage.fish"

set -l temp_dir (mktemp -d)
or exit 1
function __sp_grasp_completion_cleanup --on-event fish_exit --inherit-variable temp_dir
	rm -f -- "$temp_dir/sentinel.txt" "$temp_dir/space file.txt" "$temp_dir/__sp_grasp_completion_command"
	rmdir -- "$temp_dir/__sp_grasp_completion_directory" "$temp_dir"
end
cd "$temp_dir"; or exit 1
touch sentinel.txt 'space file.txt'
or exit 1
mkdir __sp_grasp_completion_directory
or exit 1

function __sp_grasp_completion_command
end
function __sp_grasp_completion_directory
end
function '__sp grasp completion'
end
for cmd in __sp_grasp_completion_command __sp_grasp_completion_directory '__sp grasp completion'
	complete -c "$cmd" -f
	complete -c "$cmd" -f -l delegated
	complete -c "$cmd" -l choose -x -a chosen-value
end

function __sp_grasp_expect_completion --argument-names line expected presence
	set -l candidates (complete -C "$line" | string replace -r '\t.*$' '')
	set -l found no
	if contains -- "$expected" $candidates
		set found yes
	end
	if test "$found" != "$presence"
		printf 'FAIL: %s: expected %s to be present=%s\n' "$line" "$expected" "$presence" >&2
		printf 'Candidates: <%s>\n' $candidates >&2
		exit 1
	end
end

__sp_grasp_expect_completion 'grasp __sp_grasp_completion_c' __sp_grasp_completion_command yes
__sp_grasp_expect_completion 'grasp sent' sentinel.txt yes
__sp_grasp_expect_completion 'grasp --cmd sent' sentinel.txt no
__sp_grasp_expect_completion 'grasp --file __sp_grasp_completion_c' __sp_grasp_completion_command no
__sp_grasp_expect_completion 'grasp --sy' --syntax yes
__sp_grasp_expect_completion 'grasp --line ' __sp_grasp_completion_command no
__sp_grasp_expect_completion 'grasp --search ' __sp_grasp_completion_command no

for prefix in grasp ppage 'grasp --cmd' 'grasp --' 'grasp -np' \
	'grasp --search query' 'grasp --search="two words"' 'grasp --prompt prompt' \
	'grasp -l 3' 'grasp -l3' 'grasp --tail' 'grasp --tail=20' 'grasp -t20' \
	'grasp --syntax' 'grasp --syntax=json' 'grasp --no-syntax' 'grasp -F'
	__sp_grasp_expect_completion "$prefix __sp_grasp_completion_command --del" --delegated yes
end

__sp_grasp_expect_completion 'grasp __sp_grasp_completion_command --choose cho' chosen-value yes
__sp_grasp_expect_completion 'grasp __sp_grasp_completion_command --file --del' --delegated yes
__sp_grasp_expect_completion 'grasp __sp_grasp_completion_command --sy' --syntax no
__sp_grasp_expect_completion 'grasp __sp_grasp_completion_command sent' sentinel.txt no
__sp_grasp_expect_completion "grasp '__sp grasp completion' --del" --delegated yes
__sp_grasp_expect_completion 'grasp git che' checkout yes
__sp_grasp_expect_completion 'grasp string match --reg' --regex yes
__sp_grasp_expect_completion 'grasp fish --no-con' --no-config yes
__sp_grasp_expect_completion 'grasp --file __sp_grasp_completion_command --del' --delegated no
__sp_grasp_expect_completion 'grasp sentinel.txt sent' sentinel.txt yes
__sp_grasp_expect_completion "grasp 'space file.txt' sent" sentinel.txt yes
__sp_grasp_expect_completion 'grasp __sp_grasp_completion_directory --del' --delegated no
__sp_grasp_expect_completion 'grasp --cmd __sp_grasp_completion_directory --del' --delegated yes

touch __sp_grasp_completion_command
or exit 1
__sp_grasp_expect_completion 'grasp __sp_grasp_completion_command --del' --delegated no
__sp_grasp_expect_completion 'grasp __sp_grasp_completion_command sent' sentinel.txt yes
__sp_grasp_expect_completion 'grasp --cmd __sp_grasp_completion_command --del' --delegated yes
__sp_grasp_expect_completion 'grasp --cmd --file __sp_grasp_completion_command --del' --delegated no
__sp_grasp_expect_completion 'grasp --file --cmd __sp_grasp_completion_command --del' --delegated no

echo 'grasp completion tests passed'
