function onman -d \
	'Show a man page fetched from an online source.'
	argparse 'h/help' 'debug' 't/txt' 'text' 'groff' 'html' 'urls' 'os=' 'os-id=' 'os-version-id=' 'os-codename=' 'refresh' -- $argv
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
		echo "  --html                   Include browser-accessible HTML URLs (alongside groff/txt)"
		echo "  --urls               Print all candidate URLs (any mode) and exit; implies --html"
		echo "  --os <type>              Override OS type (e.g. Linux, Darwin, FreeBSD)"
		echo "  --os-id <id>             Override OS ID from os-release (e.g. debian, arch)"
		echo "  --os-version-id <ver>    Override VERSION_ID from os-release (e.g. 15, 43)"
		echo "  --os-codename <name>     Override VERSION_CODENAME from os-release (e.g. bookworm, noble)"
		echo "  --refresh                Refresh cache"
		return 0
	end >&2

	# resolve flags → single mode variable
	set -l flag_debug no
	set -l flag_urls no
	if set -q _flag_debug; set flag_debug yes; end
	if set -q _flag_urls; set flag_urls yes; end

	# mode: groff | txt | html  (default resolved after checking for `man`)
	set -l mode_flag_count 0
	set -l mode auto
	if set -q _flag_groff;           set mode groff; set mode_flag_count (math $mode_flag_count + 1); end
	if set -q _flag_txt; or set -q _flag_text
	                                 set mode txt;   set mode_flag_count (math $mode_flag_count + 1); end
	if set -q _flag_html;            set mode html;  set mode_flag_count (math $mode_flag_count + 1); end
	if test $mode_flag_count -gt 1
		echo "onman: --groff, --txt, and --html are mutually exclusive" >&2
		return 1
	end
	# --urls implies html when no mode flag was given
	if test "$flag_urls" = yes -a "$mode" = auto
		set mode html
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
	
	# --- if section is unset or 1, check if the binary lives outside distro paths ---
	# If it does, it was likely installed from source/manually and has a recent version;
	# use Arch Linux (rolling release) as the distro so the latest man page is fetched.
	if test -z "$section" -o "$section" = 1
		set -l bin_path (command -v $page 2>/dev/null)
		if test -n "$bin_path"
			# Non-distro paths: /usr/local, /home, /opt (but not /opt/homebrew handled by Darwin above)
			if string match -qr '^(/usr/local/|/home/|/opt/)' -- $bin_path
				if test "$flag_debug" = yes
					echo "onman: $page found at $bin_path (non-distro path) → pretend archlinux for latest" >&2
				end
				set os_id "arch"
				set os_id_like ""
				set os_version_id "20260712.0.555161"
			end
		end
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

	# --- resolve auto mode ---
	if test "$mode" = auto
		if command -q man
			set mode groff
		else
			set mode txt
		end
	end

	# --- build URL list: one URL per source, groff or txt based on mode ---
	set -l urls
	set -l url_modes  # parallel list: "groff" or "txt"

	# section suffix for URLs
	set -l sec_suffix ""
	set -l forced_section 1
	
	if test -n "$section"
		set sec_suffix ".$section"
		set forced_section $section
	end
	set -l forced_sec_suffix ".$forced_section"
	

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
		switch $mode
			case groff
				set -a urls "https://man.archlinux.org/man/$page$sec_suffix.raw"
				set -a url_modes groff
			case txt
				set -a urls "https://man.archlinux.org/man/$page$sec_suffix.txt"
				set -a url_modes txt
			case html
				set -a urls "https://man.archlinux.org/man/$page$sec_suffix"
				set -a url_modes html
		end
	end

	# manned.org: good distro coverage including BSD, albeit outdated at times
	if test -n "$manned_distro"
		switch $mode
			case groff
				set -a urls "https://manned.org/raw/$manned_distro/$page$sec_suffix"
				set -a url_modes groff
			case txt
				set -a urls "https://manned.org/txt/$manned_distro/$page$sec_suffix"
				set -a url_modes ihtml
			case html
				set -a urls "https://manned.org/man/$manned_distro/$page$sec_suffix"
				set -a url_modes html
		end
	end

	# Generic Ubuntu template for ubuntu-like
	if test "$is_ubuntu_like" = yes
		switch $mode
			case groff
				set -a urls "https://manpages.ubuntu.com/manpages/$os_codename/man$forced_section/$page$forced_sec_suffix.gz"
				set -a url_modes groff
			case html
				set -a urls "https://manpages.ubuntu.com/manpages/$os_codename/man$forced_section/$page$forced_sec_suffix.html"
				set -a url_modes html
		end
	end

	# Generic Debian template for debian-like (includes Ubuntu)
	if test "$is_debian_like" = yes
		set -l deb_codename $os_codename
		if test -z "$deb_codename" -o "$os_id" != "debian"; set deb_codename unstable; end
		switch $mode
			case groff
				set -a urls "https://manpages.debian.org/$deb_codename/$page$sec_suffix.gz"
				set -a url_modes groff
			case html
				set -a urls "https://manpages.debian.org/$deb_codename/$page$sec_suffix.html"
				set -a url_modes html
		end
	end

	if test "$os_type" = FreeBSD
		# FreeBSD man CGI (plain text / HTML)
		set -l base_url "https://man.freebsd.org/cgi/man.cgi?query=$page&manpath=FreeBSD+$os_version_id-RELEASE+and+Ports.quarterly"
		if test -n "$section"
			set base_url $base_url"&sektion=$section"
		end
		switch $mode
			case txt groff
				set -a urls $base_url"&format=ascii"
				set -a url_modes txt
			case html
				set -a urls $base_url
				set -a url_modes html
		end
	end

	# Arch Linux used as universal fallback for everyone else
	if test "$is_arch_like" = no
		switch $mode
			case groff
				set -a urls "https://man.archlinux.org/man/$page$sec_suffix.raw"
				set -a url_modes groff
			case txt
				set -a urls "https://man.archlinux.org/man/$page$sec_suffix.txt"
				set -a url_modes txt
			case html
				set -a urls "https://man.archlinux.org/man/$page$sec_suffix"
				set -a url_modes html
		end
	end

	# --- if --urls: print all candidate URLs (any mode) and exit ---
	if test "$flag_urls" = yes
		for i in (seq (count $urls))
			echo $urls[$i]
		end
		return 0
	end

	# --- try each URL ---
	set -l result_from_cache no
	for i in (seq (count $urls))
		set -l url $urls[$i]
		set -l url_mode $url_modes[$i]

		if test "$flag_debug" = yes; echo "onman: trying $url_mode $url" >&2; end
		
		set -l cache_key "onman-source:"$url
		set -l cache_fail_key "onman-source-failed:"$url
		if ! set -q _flag_refresh && __sp_blob_cache --status $cache_fail_key
			continue
		end
		
		set -l tmpfile (mktemp /tmp/online-man-XXXXXX)
		
		if set -q _flag_refresh || ! __sp_blob_cache --allow-stale --get $cache_key > $tmpfile
			set -l cmd timeout 3 dl --tries=1
			if ! test "$flag_debug" = yes
				set -a cmd --silent
			end
			set -a cmd "$url"
			$cmd > $tmpfile
			if test $status -ne 0; or test ! -s $tmpfile
				if test "$flag_debug" = yes; echo "onman: discarding $url (download failed or empty)" >&2; end
				rm -f $tmpfile
				echo failed | __sp_blob_cache --set $cache_fail_key 1h
				continue
			end
			
			__sp_blob_cache --clear $cache_fail_key
			cat $tmpfile | __sp_blob_cache --set $cache_key 7d
		else
			set result_from_cache yes
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
			set -l url_prefix (string match -rg '(^.+?://[^/]+/)' -- $url)
			echo -n (set_color --bold brwhite)'NOTE:'(set_color normal)' Non-local man page'
			if test $result_from_cache = yes
				echo -n (set_color --bold brwhite)', CACHED'(set_color normal)
			end
			echo -n '. '$url_mode' '(__sp_osc8_url $url 'sourced')' from: '$url_prefix
			echo
			echo
			if test "$url_mode" = groff
				# lower-level commands when available on Linux and BSD
				set -l cols (if test -n "$COLUMNS"; echo $COLUMNS; else; echo 80; end)
				if command -q nroff
					nroff -Tutf8 -man -rLL={$cols}n $tmpfile 2>/dev/null
				else if command -q groff
					groff -Tutf8 -man -rLL={$cols}n $tmpfile 2>/dev/null
				else if command -q mandoc
					mandoc -T utf8 $tmpfile 2>/dev/null
				else
					# NOTE: man -l fails on opensuse tumbleweed; the above low-level commands work
					MAN_KEEP_FORMATTING=1 PAGER=cat MANPAGER=cat man -l $tmpfile
				end
			else if test "$url_mode" = ihtml
				# inline html mode (only formatting and some escapes, from manned.org/txt/)
				set -l esc (printf '\033')
				sed "s/<b>/"$esc"[1m/g; s/<\/b>/"$esc"[22m/g; s/<i>/"$esc"[3m/g; s/<\/i>/"$esc"[23m/g; s/<[^>]*>//g; s/\&amp;/\&/g; s/\&lt;/</g; s/\&gt;/>/g" $tmpfile
			else if test "$url_mode" = html
				# full html mode, render with lynx or w3m?
				__sp_html2text $tmpfile
			else
				cat $tmpfile
			end
			echo
			echo 'Download URL: '(__sp_osc8_url $url)
		end | __sp_pager
		rm -f $tmpfile
		return
	end

	echo "onman: no man page found online for: $page" >&2
	return 1
end
