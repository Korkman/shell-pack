#! /bin/sh
{

set -eu

installer_log="$HOME/fish_installer_case.log"

if command -v lsb_release > /dev/null
then
	# get data from release files
	distro=$(lsb_release -si)
	version=$(lsb_release -sr | sed 's/\..*//')
elif [ -e /etc/debian_version ]
then
	# get data from release files
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
elif [ -e /etc/fedora-release ]
then
	distro=Fedora
	version=$(cat /etc/fedora-release | sed 's/\..*//')
elif [ -e "/etc/arch-release" ]
then
	distro=Arch
	version=$(cat "/etc/arch-release" | sed 's/Arch Linux //')
fi

export DEBIAN_FRONTEND=noninteractive
case "$distro-$version" in
	'Debian-11'|'Kali-'*)
		installer_case='Debian-11'
		# paste here
		echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_11/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list
		curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_11/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
		sudo apt update
		sudo apt -y install fish
	;;
	'Debian-10')
		installer_case='Debian-10'
		# paste here
		echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_10/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list
		curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
		sudo apt update
		sudo apt -y install fish
	;;
	'Debian-9')
		installer_case='Debian-9'
		# paste here
		echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_9.0/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list
		curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_9.0/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
		sudo apt update
		sudo apt -y install fish
	;;
	'Debian-8')
		installer_case='Debian-8'
		# paste here
		echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_9.0/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list
		curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_9.0/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
		sudo apt update
		sudo apt -y install fish
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
	'CentOS'*)
		installer_case='CentOS-any'
		sudo dnf install -y fish
	;;
	'Arch'*|'EndeavourOS'*|'Garuda'*)
		installer_case='Arch-any'
		sudo pacman -Sy --noconfirm fish
	;;
	*)
		installer_case='none'
		echo "Cannot install fish :-("
	;;
esac

touch "$installer_log"
echo "args: $0" >> "$installer_log"
echo "detected os: $distro-$version" >> "$installer_log"
echo "used method: $installer_case" >> "$installer_log"

exit
}
