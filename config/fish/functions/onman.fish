function onman -d \
	'Show a man page fetched from an online source.'
	argparse 'h/help' 'debug' 't/txt' 'text' 'groff' 'os=' 'os-id=' 'os-version-id=' 'os-codename=' -- $argv
	or return 1

	if set -q _flag_help; or test (count $argv) -eq 0
		echo "Usage: onman [options] [section] <page>"
		echo
		echo "Online-Manual"
		echo "Downloads a man page from an online source and displays it."
		echo "  section       Optional section number (e.g. 1, 8)"
		echo "  page          Name of the man page (e.g. rsync)"
		echo
		echo "Options:"
		echo "  --debug       Print each URL attempted to stderr"
		echo "  --txt/--text  Force plain-text URLs (skip groff sources)"
		echo "  --groff       Force groff URLs (skip plain-text sources)"
		echo "  --os <type>              Override OS type (e.g. Linux, Darwin, FreeBSD)"
		echo "  --os-id <id>             Override OS ID from os-release (e.g. debian, arch)"
		echo "  --os-version-id <ver>    Override VERSION_ID from os-release (e.g. 15, 43)"
		echo "  --os-codename <name>     Override VERSION_CODENAME from os-release (e.g. bookworm, noble)"
		return 0
	end >&2

	# resolve flag aliases
	set -l flag_debug no
	set -l flag_txt no
	set -l flag_groff no
	if set -q _flag_debug; set flag_debug yes; end
	if set -q _flag_txt; or set -q _flag_text; set flag_txt yes; end
	if set -q _flag_groff; set flag_groff yes; end
	if test "$flag_txt" = yes -a "$flag_groff" = yes
		echo "onman: --txt and --groff are mutually exclusive" >&2
		return 1
	end

	set -l page ""
	set -l section ""
	if test (count $argv) -ge 2
		set section $argv[1]
		set page $argv[2]
	else
		set page $argv[1]
	end

	# --- read os-release once; apply flag overrides immediately ---
	set -l os_type (uname -s)
	if set -q _flag_os; set os_type $_flag_os; end

	set -l os_id ""
	set -l os_id_like ""
	set -l os_version_id ""
	set -l os_codename ""
	if test -r /etc/os-release
		set os_id       (grep -m1 '^ID='               /etc/os-release | string replace 'ID='               '' | string trim -c '"')
		set os_id_like  (grep -m1 '^ID_LIKE='          /etc/os-release | string replace 'ID_LIKE='          '' | string trim -c '"')
		set os_version_id (grep -m1 '^VERSION_ID='     /etc/os-release | string replace 'VERSION_ID='       '' | string trim -c '"')
		set os_codename (grep -m1 '^VERSION_CODENAME=' /etc/os-release | string replace 'VERSION_CODENAME=' '' | string trim -c '"')
	end
	if set -q _flag_os_id;         set os_id         $_flag_os_id;         set os_id_like ""; end
	if set -q _flag_os_version_id; set os_version_id $_flag_os_version_id; end
	if set -q _flag_os_codename;   set os_codename   $_flag_os_codename;   end

	# --- detect distro for manned.org slug ---
	set -l manned_distro ""

	if test "$os_type" = Linux
		# Map known IDs to manned.org distro slugs
		# manned.org slugs: debian-trixie, debian-bookworm, ubuntu-questing, arch, fedora-43, alpine-3.23, etc.
		switch $os_id
			case debian ubuntu
				set manned_distro "$os_id-$os_codename"
			case fedora centos
				set manned_distro "$os_id-$os_version_id"
			case arch 'arch*'
				set manned_distro "arch"
			case alpine
				# remove third digit of alpine version
				set -l alpine_ver (string replace -r '\.[^.]*$' '' -- "$os_version_id")
				set manned_distro "alpine-$alpine_ver"
			case '*'
				# check ID_LIKE for debian/arch/fedora lineage
				if string match -q '*debian*' -- $os_id_like; or string match -q '*ubuntu*' -- $os_id_like
					set manned_distro "debian"
				else if string match -q '*arch*' -- $os_id_like
					set manned_distro "arch"
				else if string match -q '*fedora*' -- $os_id_like; or string match -q '*rhel*' -- $os_id_like
					set manned_distro "fedora"
				end
		end
	else if test "$os_type" = FreeBSD
		set manned_distro "freebsd-$os_version_id"
	else if test "$os_type" = NetBSD
		set manned_distro "netbsd-$os_version_id"
	else if test "$os_type" = OpenBSD
		set manned_distro "openbsd-$os_version_id"
	else if test "$os_type" = Darwin
		# macOS: FreeBSD-like
		set manned_distro "freebsd"
	end

	# --- decide rendering mode ---
	set -l use_groff no
	if test "$flag_txt" = yes
		set use_groff no
	else if test "$flag_groff" = yes
		set use_groff yes
	else if command -q man
		set use_groff yes
	end

	# --- build URL list: one URL per source, groff or txt based on mode ---
	set -l urls
	set -l url_modes  # parallel list: "groff" or "txt"

	# section suffix for URLs
	set -l sec_suffix ""
	if test -n "$section"
		set sec_suffix ".$section"
	end

	# distro lineage flags
	set -l is_debian_like no
	set -l is_ubuntu_like no
	set -l is_arch_like no
	if test "$os_type" = Linux
		if test "$os_id" = ubuntu; or string match -q '*ubuntu*' -- $os_id_like
			set is_ubuntu_like yes
			set is_debian_like yes
		end
		if test "$os_id" = debian; or string match -q '*debian*' -- $os_id_like; or test "$is_ubuntu_like" = yes
			set is_debian_like yes
		end
		if string match -q 'arch*' -- $os_id; or string match -q '*arch*' -- $os_id_like
			set is_arch_like yes
		end
	end

	if test "$is_arch_like" = yes
		# Arch Linux itself prioritized over manned.org
		if test "$use_groff" = yes
			set -a urls "https://man.archlinux.org/man/$page$sec_suffix.raw"
			set -a url_modes groff
		else
			set -a urls "https://man.archlinux.org/man/$page$sec_suffix.txt"
			set -a url_modes txt
		end
	end

	# manned.org: good distro coverage including BSD, albeit outdated at times
	if test -n "$manned_distro"
		if test "$use_groff" = yes
			set -a urls "https://manned.org/raw/$manned_distro/$page$sec_suffix"
			set -a url_modes groff
		else
			set -a urls "https://manned.org/txt/$manned_distro/$page$sec_suffix"
			set -a url_modes html
		end
	end

	# Generic Ubuntu template for ubuntu-like
	if test "$is_ubuntu_like" = yes
		if test "$use_groff" = yes
			set -a urls "https://manpages.ubuntu.com/man$section/$page.gz"
			set -a url_modes groff
		end
	end

	# Generic Debian template for debian-like (includes Ubuntu)
	if test "$is_debian_like" = yes
		if test "$use_groff" = yes
			set -a urls "https://manpages.debian.org/man$section/$page.gz"
			set -a url_modes groff
		end
	end

	if test "$os_type" = FreeBSD
		# FreeBSD man CGI (plain text only)
		set -l base_url "https://man.freebsd.org/cgi/man.cgi?query=$page&manpath=FreeBSD+$os_version_id-RELEASE+and+Ports.quarterly&format=ascii"
		if test -n "$section"
			set -a urls $base_url"&sektion=$section"
		else
			set -a urls $base_url
		end
		set -a url_modes txt
	end

	# Arch Linux used as universal fallback for everyone else
	if test "$is_arch_like" = no
		if test "$use_groff" = yes
			set -a urls "https://man.archlinux.org/man/$page$sec_suffix.raw"
			set -a url_modes groff
		else
			set -a urls "https://man.archlinux.org/man/$page$sec_suffix.txt"
			set -a url_modes txt
		end
	end

	# --- try each URL ---
	for i in (seq (count $urls))
		set -l url $urls[$i]
		set -l url_mode $url_modes[$i]

		if test "$flag_debug" = yes; echo "onman: trying $url_mode $url" >&2; end

		set -l tmpfile (mktemp /tmp/online-man-XXXXXX)
		if test "$flag_debug" = yes
			timeout 3 dl --tries=1 "$url" > $tmpfile
		else
			timeout 3 dl --silent --tries=1 "$url" > $tmpfile 2>/dev/null
		end
		
		#if test "$flag_debug" = yes; echo "onman: tmpfile = $tmpfile" >&2; read; end
		
		if test $status -ne 0; or test ! -s $tmpfile
			if test "$flag_debug" = yes; echo "onman: discarding $url (download failed or empty)" >&2; end
			rm -f $tmpfile
			continue
		end

		if test "$url_mode" = groff
			# sanity: must look like groff (starts with ' or .)
			set -l first_char (head -c 1 $tmpfile)
			if test "$first_char" != '.' -a "$first_char" != "'"
				if test "$flag_debug" = yes; echo "onman: discarding $url (not groff, first char: '$first_char')" >&2; end
				rm -f $tmpfile
				continue
			end
		else if test "$url_mode" = txt
			# sanity: reject obvious HTML error pages
			if string match -q '<html*' -- (string lower -- (head -c 20 $tmpfile))
				if test "$flag_debug" = yes; echo "onman: discarding $url (HTML response)" >&2; end
				rm -f $tmpfile
				continue
			end
		end

		# Render: prepend source header, then page.
		# For groff, use groff/mandoc/man -l so bold/overstrike sequences are always
		# emitted regardless of whether stdout is a tty.
		begin
			printf (set_color --bold brwhite)'NOTE:'(set_color normal)' Not a local manpage, sourced from %s\n\n' $url
			if test "$url_mode" = groff
				# lower-level commands when available on Linux and BSD
				if command -q groff
					groff -Tutf8 -man $tmpfile 2>/dev/null
				else if command -q mandoc
					mandoc -T utf8 $tmpfile 2>/dev/null
				else
					# NOTE: man -l fails on opensuse tumbleweed; the above low-level commands work
					MAN_KEEP_FORMATTING=1 PAGER=cat MANPAGER=cat man -l $tmpfile
				end
			else if test "$url_mode" = html
				set -l esc (printf '\033')
				sed "s/<b>/"$esc"[1m/g; s/<\/b>/"$esc"[22m/g; s/<i>/"$esc"[3m/g; s/<\/i>/"$esc"[23m/g; s/<[^>]*>//g; s/\&amp;/\&/g; s/\&lt;/</g; s/\&gt;/>/g" $tmpfile
			else
				cat $tmpfile
			end
		end | __sp_pager
		rm -f $tmpfile
		return
	end

	echo "onman: no man page found online for: $page" >&2
	return 1
end
