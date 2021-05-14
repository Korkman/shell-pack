function ggit -d \
	"Interactive git commit"
	
	if set -q argv[1]
		set -l subcommand "$argv[1]"
		set -e argv[1]
		__ggit_$subcommand $argv
		return
	end
	
	set __ggit_cache_dir "$HOME/.cache/shell-pack/ggit"
	mkdir -p "$__ggit_cache_dir"
	set msg_filename "$__ggit_cache_dir/message.$fish_pid.txt"
	
	set -l skim_cmd (__skimcmd)
	set -l skim_binds (printf %s \
	"enter:execute(echo {q} >> '$msg_filename')+clear-query+refresh-preview,"\
	"double-click:ignore,"\
	"alt-s:preview(git -c color.ui=always status),"\
	"alt-c:execute(echo commit)+accept,"\
	"alt-a:execute(echo add)+accept,"\
	"alt-d:execute(echo diff)+accept,"\
	"alt-x:execute(echo reset)+accept,"\
	"f5:execute(echo refresh)+accept,"\
	"alt-m:execute(echo message)+accept,"\
	"f4:execute(echo message)+accept,"\
	"f10:abort,"\
	"esc:cancel"
	)
	set -l skim_help "ggit | alt-a:add alt-x:reset alt-c:commit alt-m:message alt-s:full-status f5:refresh esc:cancel"

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
			--preview-window down \
		| while read -l line; set -a results "$line"; end
		
		switch "$results[1]"
			case "refresh"
				continue
			case "commit"
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
						echo "Commit completed. Use git commit --amend to undo. git push to upload."
					end
				else
					echo "Aborted"
				end
			case "diff"
				__ggit_set_filename "$results[2]" || return
				git diff --color=always "$filename" | less -R
				continue
			case "add"
				for line in $results[2..]
					__ggit_set_filename "$line" || return
					git add "$filename" > /dev/null
				end
				continue
			case "reset"
				for line in $results[2..]
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

function __ggit_set_filename -S -d "Set variable filename from git status argv[1]"
	set filename (echo "$argv[1]" | __ggit_file_from_status)
	if test ! -e "$filename"
		echo "reset: error processing files"
		return 1
	end
end

function __ggit_diff_preview -d "Show state of file and diff"
	__ggit_set_filename "$argv[1]" || return
	set msg_filename "$argv[2]"
	
	# show commit message to this point
	if [ -e "$msg_filename" ]
		echo "staged commit message:"
		cat "$msg_filename"
		echo
	end
	
	# grep two-symbol status
	set gstatus (git status --porcelain "$filename" | head -n1 | string replace --regex "^(.?.?).*" "\$1")
	set index_status (echo "$gstatus" | string sub --start 1 --length 1)
	set wtree_status (echo "$gstatus" | string sub --start 2 --length 1)
	
	# show a nice status
	#echo "status: ["(set_color -b bryellow; set_color black)"$gstatus"(set_color normal)"]"
	echo "status: index="(echo $index_status|string escape)" tree="(echo $wtree_status|string escape)
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
	
	git diff --color=always "$filename"
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
