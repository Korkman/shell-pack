function untag --description 'Unset session tag to display in window title'
	set -q __session_tag
	and set -e __session_tag
	return 0
end
