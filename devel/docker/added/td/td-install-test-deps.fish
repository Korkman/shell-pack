function td-install-test-deps -d \
	"Install the packages the td-test-* modules need with the available package manager"
	argparse 'h/help' -- $argv
	or return 2

	if set -q _flag_help
		echo (functions --details --verbose (status function))[5]
		echo "Usage: td install-test-deps"
		echo
		echo "  Installs the binaries used by the td-test-* modules, including compression"
		echo "  tools, file, script, pv, ssh and git. Uses apk, zypper, dnf, pacman or apt-get,"
		echo "  whichever is found first, through sudo when not running as root."
		echo "  Returns non-zero if the install fails or a binary is still missing."
		set -q _flag_help
		and return 0
		or return 1
	end >&2

	# env is a no-op prefix, so the command is never empty when running as root
	set -l sudo env
	if test (id -u) -ne 0; and command -q sudo
		set sudo sudo
	end

	if command -q apk
		set -l pkgs tar gzip bzip2 xz zstd lzip lzop lz4 brotli cpio zip unzip 7zip squashfs-tools file util-linux-misc pv openssh-client git
		$sudo apk update; or return 1
		$sudo apk add $pkgs; or return 1
	else if command -q zypper
		set -l pkgs tar gzip bzip2 xz zstd lzip lzop lz4 brotli cpio zip unzip p7zip-full squashfs file util-linux pv openssh git
		$sudo zypper --non-interactive refresh; or return 1
		$sudo zypper --non-interactive install $pkgs; or return 1
	else if command -q dnf
		set -l pkgs tar gzip bzip2 xz zstd lzip lzop lz4 brotli cpio zip unzip p7zip p7zip-plugins squashfs-tools file util-linux pv openssh-clients git
		$sudo dnf -y install $pkgs; or return 1
	else if command -q pacman
		set -l pkgs tar gzip bzip2 xz zstd lzip lzop lz4 brotli cpio zip unzip p7zip squashfs-tools file util-linux pv openssh git
		$sudo pacman -Sy --noconfirm --needed $pkgs; or return 1
	else if command -q apt-get
		set -l pkgs tar gzip bzip2 xz-utils zstd lzip lzop lz4 brotli ncompress cpio zip unzip p7zip-full squashfs-tools file bsdutils pv openssh-client git
		$sudo env DEBIAN_FRONTEND=noninteractive apt-get update; or return 1
		$sudo env DEBIAN_FRONTEND=noninteractive apt-get -y install $pkgs; or return 1
	else
		echo "No supported package manager found (apk, zypper, dnf, pacman, apt-get)" >&2
		return 1
	end

	# report binaries which are still missing, e.g. when a package name differs on this distro
	set -l missing
	for tool in tar gzip bzip2 xz zstd lzip lzop lz4 brotli cpio zip unzip mksquashfs unsquashfs file script pv ssh git
		command -q $tool; or set -a missing $tool
	end
	if not command -q 7z; and not command -q 7zz; and not command -q 7za
		set -a missing 7z
	end
	if set -q missing[1]
		echo "td install-test-deps: still missing after install: $missing" >&2
		return 1
	end
	echo "td install-test-deps: all test dependencies are installed"
end
