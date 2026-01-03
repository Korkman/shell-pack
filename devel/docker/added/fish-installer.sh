#! /bin/sh
{

set -eu

# automatically installs fish shell on various (all?) distros
# notable environment variables:
# - FISH_NIGHTLY=yes - install latest nightly build
# - FISH_STATIC=yes - force static release binary

main() {
	installer_log="$HOME/fish_installer.log"
	echo "fish installer started, logging to '$installer_log'"
	touch "$installer_log"
	echo "args: $0" >> "$installer_log"
	# finds latest release versions on github via api.github.com
	FISH_VERSION=$(get_latest_fish_version) || FISH_VERSION="4.1.2"
	fish_latest="$FISH_VERSION"
	fish_static_latest="$FISH_VERSION"
	cmake_version="3.27.0"
	deploy_channel="release"
	deploy_branch="4"
	if [ "${FISH_NIGHTLY:-no}" = "yes" ]
	then
		deploy_channel="nightly"
		deploy_branch="master"
	fi
	MAKE_J=${MAKE_J:-1} # NOTE: going beyond 1 sometimes deadlocks, 2 gives OOM in default podman machines
	
	if [ "${FISH_STATIC:-no}" = "yes" ]
	then
		installer_case="Static"
	else
		installer_case=$(get_installer_for_distro)
	fi
	run_installer "$installer_case"
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
	curl -fsSL "https://github.com/fish-shell/fish-shell/releases/download/$version/fish-$version.tar.xz" > fish.tar.xz
	tar -xJf fish.tar.xz
	cd fish-*
	cmake .
	make "-j$MAKE_J"
	make install
}

install_cmake() {
	curl -fsSL "https://github.com/Kitware/CMake/releases/download/v$cmake_version/cmake-$cmake_version-linux-x86_64.sh" > cmake.sh
	chmod +x cmake.sh
	./cmake.sh --prefix=/usr/local --exclude-subdir --skip-license
}

get_latest_fish_version() {
	# get latest release version from github api
	if command -v curl > /dev/null
	then
		curl -fsSL "https://api.github.com/repos/fish-shell/fish-shell/releases/latest" | grep '"tag_name":' | sed -E 's/.*: "([^"]+)".*/\1/'
	else
		wget -q -O- "https://api.github.com/repos/fish-shell/fish-shell/releases/latest" | grep '"tag_name":' | sed -E 's/.*: "([^"]+)".*/\1/'
	fi
}

get_installer_for_distro() {
	# get data from release files
	if [ -e /etc/os-release ]
	then
		# read ID, VERSION_ID (major) and ID_LIKE from /etc/os-release without importing all variables
		distro=$(. /etc/os-release; echo "$ID")
		distro_version=$(. /etc/os-release; echo "${VERSION_ID:-}" | cut -d. -f1)
		distro_like=$(. /etc/os-release; echo "${ID_LIKE:-}")
	else
		echo "Distro unsuported by fish-installer.sh - check list for release file" >> "$installer_log"
		ls "/etc" >> "$installer_log"
		exit
	fi
	
	# select installer_case for specific distros
	case "$distro" in
		'debian')
			# only the two most recent releases have repos. for anything older, use static binary
			if [ "$distro_version" = "" ] || [ "$distro_version" -ge 13 ]
			then
				installer_case="Debian-13"
			elif [ "$distro_version" -lt 12 ]
			then
				installer_case="Static"
			else
				installer_case="Debian-$distro_version"
			fi
		;;
		'ubuntu')
			installer_case="Ubuntu-Any"
		;;
		'fedora')
			installer_case="Redhat-Any"
		;;
		'arch')
			installer_case="Archlinux-Any"
		;;
		*)
			# select installer_case based on ID_LIKE
			if echo "$distro_like" | grep -Fwq "fedora"
			then
				installer_case="Redhat-Any"
			elif echo "$distro_like" | grep -Fwq "ubuntu"
			then
				installer_case="Ubuntu-Any"
			elif echo "$distro_like" | grep -Fwq "debian"
			then
				installer_case="Static"
			elif echo "$distro_like" | grep -Fwq "arch"
			then
				installer_case="Archlinux-Any"
			else
				installer_case="Static"
			fi
		;;
	esac

	echo "detected os: $distro-$distro_version" >> "$installer_log"
	if [ "$distro_like" != "" ]
	then
		echo "os like: $distro_like" >> "$installer_log"
	fi
	
	echo "$installer_case"
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
			curl -fsSL "https://download.opensuse.org/repositories/shells:fish:$suse_build_path2/Debian_13/Release.key" | gpg --dearmor | sudo tee "/etc/apt/trusted.gpg.d/shells_fish_$suse_build_path3.gpg" > /dev/null
			sudo apt-get update
			sudo apt-get -y install fish
		;;
		'Debian-12') # bookworm
			# paste here
			echo "deb http://download.opensuse.org/repositories/shells:/fish:/$suse_build_path1/Debian_12/ /" | sudo tee "/etc/apt/sources.list.d/shells:fish:$suse_build_path2.list"
			curl -fsSL "https://download.opensuse.org/repositories/shells:fish:$suse_build_path2/Debian_12/Release.key" | gpg --dearmor | sudo tee "/etc/apt/trusted.gpg.d/shells_fish_$suse_build_path3.gpg" > /dev/null
			sudo apt-get update
			sudo apt-get -y install fish
		;;
		'Debian-11') # bullseye
			# paste here
			echo "deb http://download.opensuse.org/repositories/shells:/fish:/$suse_build_path1/Debian_11/ /" | sudo tee "/etc/apt/sources.list.d/shells:fish:$suse_build_path2.list"
			curl -fsSL "https://download.opensuse.org/repositories/shells:fish:$suse_build_path2/Debian_11/Release.key" | gpg --dearmor | sudo tee "/etc/apt/trusted.gpg.d/shells_fish_$suse_build_path3.gpg" > /dev/null
			sudo apt-get update
			sudo apt-get -y install fish
		;;
		'Debian-10') # buster
			# paste here
			echo "deb http://download.opensuse.org/repositories/shells:/fish:/$suse_build_path1/Debian_10/ /" | sudo tee "/etc/apt/sources.list.d/shells:fish:$suse_build_path2.list"
			curl -fsSL "https://download.opensuse.org/repositories/shells:fish:$suse_build_path2/Debian_10/Release.key" | gpg --dearmor | sudo tee "/etc/apt/trusted.gpg.d/shells_fish_$suse_build_path3.gpg" > /dev/null
			sudo apt-get update
			sudo apt-get -y install fish
		;;
		'Debian-Make') # deprecated method, use static binary build by default
			apt-get -y install build-essential gettext libncurses5-dev git
			cd /usr/local/src
			install_cmake >> "$installer_log" 2>&1
			build_fish "$fish_latest" >> "$installer_log" 2>&1
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
			static_release_file="https://github.com/fish-shell/fish-shell/releases/download/$fish_static_latest/fish-$fish_static_latest-linux-$install_arch.tar.xz"
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
			if command -v curl > /dev/null
			then
				curl -fsSL "$static_release_file" > fish-static.tar.xz
			elif command -v wget > /dev/null
			then
				wget -O fish-static.tar.xz "$static_release_file"
			else
				echo "neither curl nor wget available" | tee -a "$installer_log"
				exit 1
			fi

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
