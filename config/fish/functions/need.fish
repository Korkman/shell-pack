function need -d \
	"Install or remove the packages providing tools with apt, apk, pacman, dnf, yum, zypper, pkg, emerge, brew or nix, tools are given by command name"
	argparse 'a/ask' 'r/remove' 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo "Usage: need [--ask] [--remove] TOOL..."
		echo
		echo "  Installs the packages providing TOOL... with apt-get, apk, pacman, dnf, yum, zypper,"
		echo "  pkg, emerge, brew or nix. A TOOL is a command"
		echo "  name, or a package name if no mapping exists. Alternatives may be given as"
		echo "  'a|b', any of them satisfies the tool. Tools already available are skipped."
		echo "  -r/--remove  remove the packages instead, without checking availability"
		echo "  -a/--ask     ask before running the package manager, when not on a terminal"
		echo "               the command is printed and need returns 1"
		return 0
	end

	set -l tools $argv
	set -q tools[1]; or return 0

	set -l action install
	set -q _flag_remove; and set action remove

	# packages are named as on Debian, apk names are translated below where they differ
	set -l packages
	for tool in $tools
		set -l alts (string split '|' -- $tool)
		if test $action = install
			set -l found 0
			for alt in $alts
				if command -vq $alt
					set found 1
					break
				end
			end
			test $found = 1; and continue
		end
		set -l pkg
		switch $alts[1]
			case ssh; set pkg openssh-client
			case xz lzma; set pkg xz-utils
			case gunzip; set pkg gzip
			case 7z; set pkg p7zip-full
			case mksquashfs unsquashfs; set pkg squashfs-tools
			case script; set pkg bsdutils
			case compress; set pkg ncompress
			case '*'; set pkg $alts[1]
		end
		contains -- $pkg $packages; or set -a packages $pkg
	end
	set -q packages[1]; or return 0

	set -l manager
	if command -vq apt-get
		set manager apt
	else if command -vq apk
		set manager apk
	else if command -vq pacman
		set manager pacman
	else if command -vq dnf
		set manager dnf
	else if command -vq yum
		set manager yum
	else if command -vq zypper
		set manager zypper
	else if command -vq pkg
		set manager pkg
	else if command -vq emerge
		set manager emerge
	else if command -vq brew
		set manager brew
	else if command -vq nix
		set manager nix-profile
	else if command -vq nix-env
		set manager nix-env
	end

	set -l shown
	for pkg in $packages
		switch "$manager/$pkg"
			case apk/xz-utils pacman/xz-utils dnf/xz-utils yum/xz-utils zypper/xz-utils pkg/xz-utils brew/xz-utils 'nix*/xz-utils'
				set -a shown xz
			case apk/p7zip-full
				set -a shown 7zip
			case pacman/p7zip-full pkg/p7zip-full brew/p7zip-full 'nix*/p7zip-full'
				set -a shown p7zip
			case dnf/p7zip-full yum/p7zip-full
				set -a shown p7zip p7zip-plugins
			case apk/bsdutils
				set -a shown util-linux-misc
			case pacman/bsdutils dnf/bsdutils yum/bsdutils zypper/bsdutils brew/bsdutils 'nix*/bsdutils'
				set -a shown util-linux
			case pacman/openssh-client brew/openssh-client 'nix*/openssh-client'
				set -a shown openssh
			case pkg/openssh-client
				set -a shown openssh-portable
			case dnf/openssh-client yum/openssh-client
				set -a shown openssh-clients
			case zypper/openssh-client
				set -a shown openssh-clients
			case 'nix*/squashfs-tools' zypper/squashfs-tools brew/squashfs-tools
				set -a shown squashfs
			case emerge/openssh-client
				set -a shown net-misc/openssh
			case emerge/xz-utils
				set -a shown app-arch/xz-utils
			case emerge/gzip
				set -a shown app-arch/gzip
			case emerge/p7zip-full
				set -a shown app-arch/p7zip
			case emerge/squashfs-tools
				set -a shown sys-fs/squashfs-tools
			case emerge/bsdutils
				set -a shown sys-apps/util-linux
			case emerge/ncompress
				set -a shown app-arch/ncompress
			case '*'
				set -a shown $pkg
		end
	end

	if test -z "$manager"
		echo "No supported package manager found (apt-get, apk, pacman, dnf, yum, zypper, pkg, emerge, brew, nix or nix-env), $action these manually: $packages" >&2
		return 1
	end

	echo "Packages to $action: $shown" >&2
	set -l nix_pkgs (string replace -r '^' 'nixpkgs#' -- $shown)
	set -l nix_attrs (string replace -r '^' 'nixpkgs.' -- $shown)
	set -l hint
	switch "$manager/$action"
		case apt/install; set hint "apt install $shown"
		case apt/remove; set hint "apt remove $shown"
		case apk/install; set hint "apk add $shown"
		case apk/remove; set hint "apk del $shown"
		case pacman/install; set hint "pacman -Sy --needed $shown"
		case pacman/remove; set hint "pacman -R $shown"
		case dnf/install; set hint "dnf install $shown"
		case dnf/remove; set hint "dnf remove $shown"
		case yum/install; set hint "yum install $shown"
		case yum/remove; set hint "yum remove $shown"
		case zypper/install; set hint "zypper -n install $shown"
		case zypper/remove; set hint "zypper -n remove $shown"
		case pkg/install; set hint "pkg install -y $shown"
		case pkg/remove; set hint "pkg delete -y $shown"
		case emerge/install; set hint "emerge --noreplace $shown"
		case emerge/remove; set hint "emerge --unmerge $shown"
		case brew/install; set hint "brew install $shown"
		case brew/remove; set hint "brew uninstall $shown"
		case nix-profile/install; set hint "nix profile install $nix_pkgs"
		case nix-profile/remove; set hint "nix profile remove $shown"
		case nix-env/install; set hint "nix-env -iA $nix_attrs"
		case nix-env/remove; set hint "nix-env -e $shown"
	end

	if set -q _flag_ask
		if not isatty stdin
			echo "Run with: $hint" >&2
			return 1
		end

		read -l -P "Run '$hint' now? [Y/n] " answer
		if not string match -qri '^(y|yes)?$' -- "$answer"
			echo "Run with: $hint" >&2
			return 1
		end
	end

	set -l sudo env
	test (id -u) -ne 0; and command -vq sudo; and set sudo sudo

	switch "$manager/$action"
		case apt/install
			$sudo env DEBIAN_FRONTEND=noninteractive apt-get update; and $sudo env DEBIAN_FRONTEND=noninteractive apt-get -y install $shown
		case apt/remove
			$sudo env DEBIAN_FRONTEND=noninteractive apt-get -y remove $shown
		case apk/install
			$sudo apk update; and $sudo apk add $shown
		case apk/remove
			$sudo apk del $shown
		case pacman/install
			$sudo pacman -Sy --needed --noconfirm $shown
		case pacman/remove
			$sudo pacman -R --noconfirm $shown
		case dnf/install
			$sudo dnf -y install $shown
		case dnf/remove
			$sudo dnf -y remove $shown
		case yum/install
			$sudo yum -y install $shown
		case yum/remove
			$sudo yum -y remove $shown
		case zypper/install
			$sudo zypper -n refresh; and $sudo zypper -n install $shown
		case zypper/remove
			$sudo zypper -n remove $shown
		case pkg/install
			$sudo pkg update; and $sudo pkg install -y $shown
		case pkg/remove
			$sudo pkg delete -y $shown
		case emerge/install
			$sudo emerge --noreplace $shown
		case emerge/remove
			$sudo emerge --unmerge $shown
		case brew/install
			brew install $shown
		case brew/remove
			brew uninstall $shown
		case nix-profile/install
			nix profile install $nix_pkgs
		case nix-profile/remove
			nix profile remove $shown
		case nix-env/install
			nix-env -iA $nix_attrs
		case nix-env/remove
			nix-env -e $shown
	end
	or begin
		echo "Failed to $action packages: $shown" >&2
		return 1
	end

	return 0
end
