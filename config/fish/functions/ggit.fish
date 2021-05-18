function ggit -d \
	"Interactive git commit"
	
	if set -q argv[1]
		set -l subcommand "$argv[1]"
		set -e argv[1]
		__ggit_$subcommand $argv
		return
	end
	
	set -l __ggit_cache_dir "$HOME/.cache/shell-pack/ggit"
	mkdir -p "$__ggit_cache_dir"
	set -l msg_filename "$__ggit_cache_dir/message.$fish_pid.txt"
	
	set -l skim_cmd (__skimcmd)
	set -l skim_binds (printf %s \
	"enter:execute(echo {q} >> '$msg_filename')+clear-query+refresh-preview,"\
	"double-click:ignore,"\
	"alt-s:preview(git -c color.ui=always status),"\
	"alt-c:execute(echo commit; echo {q})+accept,"\
	"alt-p:execute(echo commit_and_push; echo {q})+accept,"\
	"alt-a:execute(echo add; echo {q})+accept,"\
	"alt-d:execute(echo diff; echo {q})+accept,"\
	"alt-x:execute(echo reset; echo {q})+accept,"\
	"f5:execute(echo refresh; echo {q})+accept,"\
	"alt-m:execute(echo message)+accept,"\
	"f4:execute(echo message)+accept,"\
	"f10:abort,"\
	"esc:cancel"
	)
	set -l skim_help "ggit | alt-a:add alt-x:reset alt-c:commit alt-p:commit+push alt-m:message alt-s:full-status f5:refresh esc:cancel"
	set -l results
	set -l filename
	set -l msg_hold

	while true
		set -l git_status (git status --porcelain)
		if test $status -ne 0
			echo "git status failed"
			return 4
		end
		set -e results
		for line in $git_status; echo "$line"; end \
		| $skim_cmd \
			--bind "$skim_binds" \
			--header "$skim_help" \
			--multi \
			--height 90% \
			--disabled \
			--prompt "Commit message (enter appends): " \
			--preview "fishcall ggit diff_preview {} '$msg_filename'" \
			--query "$msg_hold" \
			--preview-window down \
		| while read -l line; set -a results "$line"; end
		
		switch "$results[1]"
			case "refresh"
				__ggit_msg_hold
				continue
			case "commit" "commit_and_push"
				__ggit_msg_append
				if test ! -e "$msg_filename"
					echo "No commit message yet!"
					continue
				end
				git status
				echo "Commit with message:"
				cat "$msg_filename"
				read -n1 -P "OK? [Y/n]" answer
				if [ "$answer" = "" -o "$answer" = "y" -o "$answer" = "Y" ]
					git commit -F "$msg_filename"
					if test $status -eq 0
						rm -f "$msg_filename"
						if test "$results[1]" = "commit_and_push"
							echo "Commit completed. Pushing ..."
							git push
						else
							echo "Commit completed. Use git commit --amend to undo. git push to upload."
						end
					end
				else
					echo "Aborted"
				end
			case "diff"
				__ggit_msg_hold
				__ggit_set_filename "$results[3]" || return
				git diff --color=always "$filename" | less -R
				continue
			case "add"
				__ggit_msg_hold
				for line in $results[3..]
					__ggit_set_filename "$line" || return
					git add "$filename" > /dev/null
				end
				continue
			case "reset"
				__ggit_msg_hold
				for line in $results[3..]
					__ggit_set_filename "$line" || return
					git reset "$filename" > /dev/null
				end
				continue
			case "message"
				mcedit "$msg_filename"
				continue
			case "*"
				#echo "Abort"
				return 0
		end
		
		break
	end
end

function __ggit_msg_hold -S -d "Grab result[2] and hold in msg_hold"
	if test "$results[2]" != ""
		set msg_hold "$results[2]"
	end
end
function __ggit_msg_append -S -d "Grab result[2] and append to msg_filename"
	if test "$results[2]" != ""
		echo "$results[2]" >> "$msg_filename"
	end
end

function __ggit_set_filename -S -d "Set variable filename from git status argv[1]"
	set filename (echo "$argv[1]" | __ggit_file_from_status)
	# file deleted in working tree? OK to be missing!
	if test (string sub --start 2 --length 1 -- "$argv[1]") = "D"; return; end
	if test ! -e "$filename"
		echo "error: file does not exist ($filename)"
		return 1
	end
end

function __ggit_diff_preview -d "Show state of file and diff"
	set -l filename
	__ggit_set_filename "$argv[1]" || return
	set -l msg_filename "$argv[2]"
	
	# show commit message to this point
	if [ -e "$msg_filename" ]
		echo "staged commit message:"
		cat "$msg_filename"
		echo
	end
		
	# grep two-symbol status
	set -l gstatus (git status --porcelain "$filename" | head -n1 | string replace --regex "^(.?.?).*" "\$1")
	set -l index_status (echo "$gstatus" | string sub --start 1 --length 1)
	set -l wtree_status (echo "$gstatus" | string sub --start 2 --length 1)
	
	# show a nice status
	#echo "status: ["(set_color -b bryellow; set_color black)"$gstatus"(set_color normal)"]"
	echo "status: index="(echo $index_status|string escape)" tree="(echo $wtree_status|string escape)" ($filename)"
	switch "$gstatus"
		case "\?\?"
			echo "untracked file"
		case " M"
			echo "modified, not staged yet"
		case " D"
			echo "deleted, not staged yet"
		case "M "
			echo "modified and staged for commit"
		case "A "
			echo "newly added and staged for commit"
		case "AM"
			echo "newly added and staged for commit, modified since add"
		case "MM"
			echo "modified and staged for commit, modified since add"
	end
	echo
	
	# directory: list content instead of diff
	if [ -d "$filename" ]
		echo "directory $filename"
		ls -A -1 --color=always "$filename"
		return
	end
	# file: does still exist?
	if [ -e "$filename" ]
		git diff --color=always "$filename"
	end
end

function __ggit_diff_full
	__ggit_set_filename "$argv[1]" || return
	git diff --color=always "$filename" | less
end

function __ggit_file_from_status -d "Strip git status from beginning of line"
	cat | string replace --regex -- "^ ?[^ ]+ +" "" | string replace --regex -- ".* -> " ""
end


# meaning of the two letters in git short status
# see also https://git-scm.com/docs/git-status
# 
# X          Y     Meaning
# -------------------------------------------------
#          [AMD]   not updated
# M        [ MD]   updated in index
# A        [ MD]   added to index
# D                deleted from index
# R        [ MD]   renamed in index
# C        [ MD]   copied in index
# [MARC]           index and work tree matches
# [ MARC]     M    work tree changed since index
# [ MARC]     D    deleted in work tree
# [ D]        R    renamed in work tree
# [ D]        C    copied in work tree
# -------------------------------------------------
# D           D    unmerged, both deleted
# A           U    unmerged, added by us
# U           D    unmerged, deleted by them
# U           A    unmerged, added by them
# D           U    unmerged, deleted by us
# A           A    unmerged, both added
# U           U    unmerged, both modified
# -------------------------------------------------
# ?           ?    untracked
# !           !    ignored
# -------------------------------------------------

