#! /bin/sh
{

set -eu

# automatically installs fish shell on most distros
# control release and version with INSTALL_FISH.
# 
# by default, the latest static release is downloaded from github:
#   INSTALL_FISH=static-latest ./fish-installer.sh
# specify a version:
#   INSTALL_FISH=static-4.7.1 ./fish-installer.sh
# to install the distro package instead:
#   INSTALL_FISH=distro
# to use the official FISH repo for the distro (limited support):
#   INSTALL_FISH=repo-release
# the official repo also offers nightlies:
#   INSTALL_FISH=repo-nightly


main() {
	installer_log="$HOME/fish_installer.log"
	echo "fish installer started, logging to '$installer_log'"
	touch "$installer_log"
	echo "args: $0" >> "$installer_log"
	cmake_version="3.27.0"
	MAKE_J=${MAKE_J:-1} # NOTE: going beyond 1 sometimes deadlocks, 2 gives OOM in default podman machines
	deploy_channel="release"
	deploy_branch="4"
	fish_version="unknown"

	INSTALL_FISH="${INSTALL_FISH:-static-latest}"
	echo "INSTALL_FISH=$INSTALL_FISH" >> "$installer_log"

	case "$INSTALL_FISH" in
		none)
			echo "INSTALL_FISH=none, skipping fish installation"
			exit 0
			;;
		static-latest)
			fish_version=$(get_latest_fish_version) || fish_version="4.1.2"
			run_installer "Static"
			;;
		static-*)
			fish_version="${INSTALL_FISH#static-}"
			run_installer "Static"
			;;
		distro)
			installer_case=$(get_distro_installer)
			run_installer "$installer_case"
			;;
		repo-release)
			deploy_channel="release"
			deploy_branch="4"
			installer_case=$(get_repo_installer)
			run_installer "$installer_case"
			;;
		repo-nightly)
			deploy_channel="nightly"
			deploy_branch="master"
			installer_case=$(get_repo_installer)
			run_installer "$installer_case"
			;;
		*)
			echo "Unknown INSTALL_FISH value: $INSTALL_FISH" >&2
			exit 1
			;;
	esac
}

download() {
	if command -v curl > /dev/null; then
		curl -fSsL "$1"
	elif command -v wget > /dev/null; then
		wget -qO- "$1"
	else
		echo "Neither curl nor wget is available, please install one of them and re-run" >&2
		exit 1
	fi
}

if command -v sudo > /dev/null
then
	sudo() {
		command sudo "$@"
	}
else
	echo "No sudo available - attempting to run package manager without"
	echo "(this usually works if you are root or have similar superpowers)"
	sudo() {
		"$@"
	}
fi

build_fish() {
	version=$1
	download "https://github.com/fish-shell/fish-shell/releases/download/$version/fish-$version.tar.xz" > fish.tar.xz
	tar -xJf fish.tar.xz
	cd fish-*
	cmake .
	make "-j$MAKE_J"
	make install
}

install_cmake() {
	download "https://github.com/Kitware/CMake/releases/download/v$cmake_version/cmake-$cmake_version-linux-x86_64.sh" > cmake.sh
	chmod +x cmake.sh
	./cmake.sh --prefix=/usr/local --exclude-subdir --skip-license
}

get_latest_fish_version() {
	# get latest release version from github api
	download "https://api.github.com/repos/fish-shell/fish-shell/releases/latest" | grep '"tag_name":' | sed -E 's/.*: "([^"]+)".*/\1/'
}

read_os_release() {
	if [ -e /etc/os-release ]
	then
		distro=$(. /etc/os-release; echo "$ID")
		distro_version=$(. /etc/os-release; echo "${VERSION_ID:-}" | cut -d. -f1)
		distro_like=$(. /etc/os-release; echo "${ID_LIKE:-}")
	else
		echo "Distro unsupported by fish-installer.sh - check list for release file" >> "$installer_log"
		ls "/etc" >> "$installer_log"
		exit 1
	fi
	echo "detected os: $distro-$distro_version" >> "$installer_log"
	if [ "$distro_like" != "" ]
	then
		echo "os like: $distro_like" >> "$installer_log"
	fi
}

# Returns installer_case for distro-native package manager (no extra repos added)
get_distro_installer() {
	read_os_release
	case "$distro" in
		'alpine')
			echo "Alpine-Any" ;;
		'debian' | 'raspbian')
			echo "Debian-Distro" ;;
		'ubuntu')
			echo "Ubuntu-Distro" ;;
		'fedora' | 'rhel' | 'centos' | 'rocky' | 'almalinux')
			echo "Redhat-Any" ;;
		'arch')
			echo "Archlinux-Any" ;;
		*)
			if echo "$distro_like" | grep -Fwq "alpine"; then
				echo "Alpine-Any"
			elif echo "$distro_like" | grep -Fwq "fedora" || echo "$distro_like" | grep -Fwq "rhel"; then
				echo "Redhat-Any"
			elif echo "$distro_like" | grep -Fwq "arch"; then
				echo "Archlinux-Any"
			elif echo "$distro_like" | grep -Fwq "ubuntu"; then
				echo "Ubuntu-Distro"
			elif echo "$distro_like" | grep -Fwq "debian"; then
				echo "Debian-Distro"
			else
				echo "Static"
			fi
			;;
	esac
}

# Returns installer_case using external repos (opensuse build service, Ubuntu PPA, etc.)
get_repo_installer() {
	read_os_release
	case "$distro" in
		'alpine')
			# Alpine fish package is from official repos only; fall back to distro
			echo "Alpine-Any" ;;
		'debian' | 'raspbian')
			# only Debian 12+ have opensuse build service repos
			if [ -n "$distro_version" ] && [ "$distro_version" -ge 12 ] 2>/dev/null
			then
				echo "Debian-$distro_version"
			else
				echo "Static"
			fi
			;;
		'ubuntu')
			echo "Ubuntu-Any" ;;
		'fedora' | 'rhel' | 'centos' | 'rocky' | 'almalinux')
			echo "Redhat-Any" ;;
		'arch')
			echo "Archlinux-Any" ;;
		*)
			if echo "$distro_like" | grep -Fwq "alpine"; then
				echo "Alpine-Any"
			elif echo "$distro_like" | grep -Fwq "fedora" || echo "$distro_like" | grep -Fwq "rhel"; then
				echo "Redhat-Any"
			elif echo "$distro_like" | grep -Fwq "arch"; then
				echo "Archlinux-Any"
			elif echo "$distro_like" | grep -Fwq "ubuntu"; then
				echo "Ubuntu-Any"
			elif echo "$distro_like" | grep -Fwq "debian"; then
				echo "Static"
			else
				echo "Static"
			fi
			;;
	esac
}

run_installer() {
	installer_case="$1"
	suse_build_path1="${deploy_channel}:/${deploy_branch}"
	suse_build_path2="${deploy_channel}:${deploy_branch}"
	suse_build_path3="${deploy_channel}_${deploy_branch}"
	ppa_tag="${deploy_channel}-${deploy_branch}"
	export DEBIAN_FRONTEND=noninteractive
	case "$installer_case" in
		'Debian-13') # trixie
			# paste here
			echo "deb http://download.opensuse.org/repositories/shells:/fish:/$suse_build_path1/Debian_13/ /" | sudo tee "/etc/apt/sources.list.d/shells:fish:$suse_build_path2.list"
			download "https://download.opensuse.org/repositories/shells:fish:$suse_build_path2/Debian_13/Release.key" | gpg --dearmor | sudo tee "/etc/apt/trusted.gpg.d/shells_fish_$suse_build_path3.gpg" > /dev/null
			sudo apt-get update
			sudo apt-get -y install fish
		;;
		'Debian-12') # bookworm
			# paste here
			echo "deb http://download.opensuse.org/repositories/shells:/fish:/$suse_build_path1/Debian_12/ /" | sudo tee "/etc/apt/sources.list.d/shells:fish:$suse_build_path2.list"
			download "https://download.opensuse.org/repositories/shells:fish:$suse_build_path2/Debian_12/Release.key" | gpg --dearmor | sudo tee "/etc/apt/trusted.gpg.d/shells_fish_$suse_build_path3.gpg" > /dev/null
			sudo apt-get update
			sudo apt-get -y install fish
		;;
		'Debian-Distro')
			sudo apt-get update
			sudo apt-get -y install fish
		;;
		'Ubuntu-Distro')
			sudo apt-get update
			sudo apt-get -y install fish
		;;
		'Alpine-Any')
			apk add fish
		;;
		'Debian-Make') # deprecated method, use static binary build by default
			apt-get -y install build-essential gettext libncurses5-dev git
			cd /usr/local/src
			install_cmake >> "$installer_log" 2>&1
			build_fish "$fish_version" >> "$installer_log" 2>&1
		;;
		'Ubuntu-Any')
			sudo apt-get -y install software-properties-common
			# paste here
			sudo apt-add-repository -y ppa:fish-shell/$ppa_tag
			sudo apt-get update
			sudo apt-get -y install fish
		;;
		'Redhat-Any')
			sudo dnf install -y fish
		;;
		'Archlinux-Any')
			sudo pacman -Sy --noconfirm fish
		;;
		'Static')
			install_arch="$(uname -m)"

			if ! command -v xz > /dev/null || ! command -v wget > /dev/null
			then
				if command -v apt-get > /dev/null
				then
					sudo apt-get update
					sudo apt-get -y install xz-utils wget
				elif command -v dnf > /dev/null
				then
					sudo dnf update
					sudo dnf install -y xz wget
				elif command -v pacman > /dev/null
				then
					sudo pacman -Sy --noconfirm xz wget
				else
					echo "No suitable package manager found to install xz and wget, please install them manually and re-run" >&2
					exit 1
				fi
			fi

			static_release_file="https://github.com/fish-shell/fish-shell/releases/download/$fish_version/fish-$fish_version-linux-$install_arch.tar.xz"
			echo "installing static release from $static_release_file" | tee -a "$installer_log"
			# test if /usr/local/bin is writable, cd and install there
			if [ -w /usr/local/bin ]
			then
				cd /usr/local/bin
			else
				# mkdir .local/bin if needed, cd there
				mkdir -p "$HOME/.local/bin"
				cd "$HOME/.local/bin"
				# if not in path, add it, assuming on next login it will be
				if ! echo "$PATH" | grep -q "$HOME/.local/bin"
				then
					echo "Warning: $HOME/.local/bin not in PATH, adding temporarily"
					echo "It may appear in PATH after next login (depends on distro)."
					echo "If it doesn't, add it manually to your shell rc file."
					export PATH="$HOME/.local/bin:$PATH"
				fi
			fi
			
			# download static release
			download "$static_release_file" > fish-static.tar.xz

			# extract and install
			tar -xJf fish-static.tar.xz
			ls -al
			rm fish-static.tar.xz
		;;
		*)
			echo "invalid installer_case: $installer_case"
			exit 1
		;;
	esac

	echo "installer completed" >> "$installer_log"
}

main

exit
}
