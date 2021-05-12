#! /bin/sh
{

set -eu

distro=ubuntu
release=xenial

if [ -e /etc/debian_version ]
then
	# get data from release files
	version=$(cat /etc/debian_version | sed 's/\..*//')
	distro=debian
	case version in
		"10") release=buster;;
		"9") release=stretch;;
		*) release=stretch;;
	esac
elif [ -e /etc/ubuntu_release ]
then
	version=$(cat /etc/ubuntu_release | sed 's/\..*//')
	distro=ubuntu
	case version in
		*) release=xenial;;
	esac
fi

export DEBIAN_FRONTEND=noninteractive
case "$distro-$release" in
	'debian-buster')
		echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_10/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list
		curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
		sudo apt update
		sudo apt -y install fish
	;;
	'debian-stretch')
		echo 'deb http://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_9.0/ /' | sudo tee /etc/apt/sources.list.d/shells:fish:release:3.list
		curl -fsSL https://download.opensuse.org/repositories/shells:fish:release:3/Debian_9.0/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/shells_fish_release_3.gpg > /dev/null
		sudo apt update
		sudo apt -y install fish
	;;
	'ubuntu-xenial')
		sudo apt-add-repository ppa:fish-shell/release-3
		sudo apt-get update
		sudo apt-get -y install fish
	;;
	*)
		echo "Cannot install fish :-("
		exit 1
	;;
esac

exit
}