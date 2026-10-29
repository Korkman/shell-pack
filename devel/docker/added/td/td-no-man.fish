function td-no-man -d \
	"Uninstall manpages with any available package manager"
	argparse 'h/help' -- $argv
	or return 2
	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td no-man"
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	if command -q apk
		apk del --purge man-pages mdocml mandoc man-db 2>/dev/null
	else if command -q zypper
		zypper --non-interactive remove man man-pages man-pages-posix 2>/dev/null
	else if command -q dnf
		dnf -y remove man-db man-pages 2>/dev/null
	else if command -q pacman
		pacman -Rns --noconfirm man-db man-pages 2>/dev/null
	else if command -q apt
		apt-get -y remove man-db manpages 2>/dev/null
	else
		echo "No supported package manager found" >&2
		return 1
	end
end
