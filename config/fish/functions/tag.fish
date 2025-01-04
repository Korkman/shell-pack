function tag --description 'Session tag to display in window title' --argument session_tag
	set -g __session_tag $session_tag
	# immediate refresh of the window title
	printf "\033]2;%s\007" (fish_title)
	return 0
end
