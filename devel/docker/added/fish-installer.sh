#! /bin/sh
{

set -eu

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
	distro=fedora
	version=$(cat /etc/fedora_release | sed 's/\..*//')
fi

export DEBIAN_FRONTEND=noninteractive
case "$distro-$version" in
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
	'Ubuntu'*)
		installer_case='Ubuntu-any'
		sudo apt-get -y install software-properties-common
		# paste here
		sudo apt-add-repository ppa:fish-shell/release-3
		sudo apt-get update
		sudo apt-get -y install fish
	;;
	'Fedora'*)
		installer_case='Fedora-any'
		dnf install -y fish
	;;
	'CentOS-8')
		installer_case='CentOS-8'
		# paste here
		cd /etc/yum.repos.d/
		wget https://download.opensuse.org/repositories/shells:fish:release:3/CentOS_8/shells:fish:release:3.repo
		yum install fish
	;;
	'CentOS-7')
		installer_case='CentOS-7'
		# paste here
		cd /etc/yum.repos.d/
		wget https://download.opensuse.org/repositories/shells:fish:release:3/CentOS_7/shells:fish:release:3.repo
		yum install fish
	;;
	'CentOS'*)
		installer_case='CentOS-any'
		dnf install -y fish
	;;
	*)
		installer_case='none'
		echo "Cannot install fish :-("
	;;
esac

echo "$0" > "/root/fish_installer_case.log"
echo "$installer_case" >> "/root/fish_installer_case.log"

exit
}