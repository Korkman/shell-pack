#! /bin/sh
{

set -eu

installer_log="$HOME/fish_installer.log"
echo "fish installer started, logging to '$installer_log'"
fish_latest="3.6.1"
cmake_version="3.27.0"
MAKE_J=${MAKE_J:-2} # NOTE: going beyond 2 gives OOM in default podman machines
touch "$installer_log"
echo "args: $0" >> "$installer_log"

# get data from release files
if command -v lsb_release > /dev/null
then
	distro=$(lsb_release -si)
	version=$(lsb_release -sr | sed 's/\..*//')
elif [ -e /etc/debian_version ]
then
	distro=Debian
	version=$(cat /etc/debian_version | sed 's/\..*//')
elif [ -e /etc/ubuntu_release ]
then
	distro=Ubuntu
	version=$(cat /etc/ubuntu_release | sed 's/\..*//')
elif [ -e /etc/fedora_release ]
then
	distro=Fedora
	version=$(cat /etc/fedora_release | sed 's/\..*//')
elif [ -e /etc/rocky-release ]
then
	distro=CentOS
	version=$(cat /etc/rocky-release | sed 's/\..*//')
elif [ -e "/etc/arch-release" ]
then
	distro=Arch
	version=$(cat "/etc/arch-release" | sed 's/Arch Linux //')
else
	echo "Distro unsuported by fish-installer.sh - check list for release file" >> "$installer_log"
	ls "/etc" >> "$installer_log"
	exit
fi

if command -v sudo > /dev/null
then
	sudo() {
		command sudo $@
	}
else
	echo "No sudo available - attempting to run package manager without"
	echo "(this usually works if you are root or have similar superpowers)"
	sudo() {
		eval $@
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

export DEBIAN_FRONTEND=noninteractive
case "$distro-$version" in
	'Debian-n/a') # sid
		installer_case='Debian-Sid'
		# paste here
		echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list
		curl -fsSL 'https://download.opensuse.org/repositories/shells:fish:release:3/Debian_12/Release.key' | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
		sudo apt-get update
		sudo apt-get -y install fish
	;;
	'Debian-12') # bookworm
		installer_case='Debian-12'
		# paste here
		echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list
		curl -fsSL 'https://download.opensuse.org/repositories/shells:fish:release:3/Debian_12/Release.key' | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
		sudo apt-get update
		sudo apt-get -y install fish
	;;
	'Debian-11'|'Kali-'*) # bullseye
		installer_case='Debian-11'
		# paste here
		echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_11/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list
		curl -fsSL 'https://download.opensuse.org/repositories/shells:fish:release:3/Debian_11/Release.key' | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
		sudo apt-get update
		sudo apt-get -y install fish
	;;
	'Debian-10') # buster
		installer_case='Debian-10'
		# paste here
		echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_10/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list
		curl -fsSL 'https://download.opensuse.org/repositories/shells:fish:release:3/Debian_10/Release.key' | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
		sudo apt-get update
		sudo apt-get -y install fish
	;;
	'Debian-9'|'Debian-8') # stretch, jessie (NOTE: wheezy won't compile any 3.x release)
		installer_case='Debian-Source-With-CMake'
		apt-get -y install build-essential gettext libncurses5-dev git
		cd /usr/local/src
		install_cmake >> "$installer_log" 2>&1
		build_fish "$fish_latest" >> "$installer_log" 2>&1
	;;
	'Ubuntu'*|'Pop'*)
		installer_case='Ubuntu-any'
		sudo apt-get -y install software-properties-common
		# paste here
		sudo apt-add-repository -y --no-update ppa:fish-shell/release-3
		sudo apt-get update
		sudo apt-get -y install fish
	;;
	'Fedora'*)
		installer_case='Fedora-any'
		sudo dnf install -y fish
	;;
	'CentOS-8')
		installer_case='CentOS-8'
		curl https://download.opensuse.org/repositories/shells:fish:release:3/CentOS_8/shells:fish:release:3.repo > sudo tee /etc/yum.repos.d/shells:fish:release:3.repo > /dev/null
		sudo yum install -y fish
	;;
	'CentOS-7')
		installer_case='CentOS-7'
		curl https://download.opensuse.org/repositories/shells:fish:release:3/CentOS_7/shells:fish:release:3.repo > sudo tee /etc/yum.repos.d/shells:fish:release:3.repo > /dev/null
		sudo yum install -y fish
	;;
	'CentOS'* | 'Rocky Linux'* )
		installer_case='CentOS-any'
		sudo dnf install -y fish
	;;
	'Arch'*|'EndeavourOS'*|'Garuda'*)
		installer_case='Arch-any'
		sudo pacman -Sy --noconfirm fish
	;;
	*)
		installer_case='none'
		echo "Unknown: $distro-$version"
		echo "Cannot install fish :-("
		exit 1
	;;
esac

echo "detected os: $distro-$version" >> "$installer_log"
echo "used method: $installer_case" >> "$installer_log"

exit
}
