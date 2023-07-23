#! /usr/bin/env sh
{

# this script
# - packages the source dir as a tar.gz
# - builds a docker / podman container
# - runs docker / podman, with tar.gz and get.sh inside
# - runs get.sh, unless started with env AUTOSTART=no

# be more strict about errors
set -eu
# initialize defaults
AUTOSTART=${AUTOSTART:-yes} # run installer in guest-startup.sh
FORCE_DOCKER=${FORCE_DOCKER:-no} # force use of docker although podman is available
FORCE_NO_SUDO=${FORCE_NO_SUDO:-no} # force skipping sudo for docker
USE_CACHED_DOWNLOADS=${USE_CACHED_DOWNLOADS:-yes} # use cached downloads (rg, fzf, etc.)
do_build="no" # perform docker build (append "build" to CLI to trigger)
build_uncached="no" # perform docker build and invalidate any cache (append "build-uncached")
if [ -z "${XDG_RUNTIME_DIR+x}" ]
then
	# XDG_RUNTIME_DIR missing, try fixing
	XDG_RUNTIME_DIR="/run/user/$(id -u)"
	# if it doesn't exist where we expect it, this might be macos or other unix
	# since podman on macos doesn't have access to /tmp (and it is arguably a bad idea to change that)
	# use a directory in $HOME instead
	if [ ! -e "$XDG_RUNTIME_DIR" ]
	then
		 XDG_RUNTIME_DIR="$HOME/.cache/shell-pack-devel/test-drive-runtime-dir"
	fi
fi
echo "Using $XDG_RUNTIME_DIR for temporary files"

if [ "${2:-}" = "build" ]
then
	do_build="yes"
fi
if [ "${2:-}" = "build-uncached" ]
then
	do_build="yes"
	build_uncached="yes"
fi

export DOCKER_BUILDKIT=1
if command -v "podman" > /dev/null && [ "$FORCE_DOCKER" != "yes" ]
then
	echo "Using podman to run test-drive (if you prefer docker, run with env FORCE_DOCKER=yes)"
	docker="podman"
	# check if podman help mentions "machine", and if so, ensure it is running
	if podman help | grep -q -E '\s+machine\s+'
	then
		if ! podman machine info | grep -q -E '\s*MachineState:\s+Running'
		then
			echo "podman machine start"
			podman machine start
		fi
	fi
else
	if [ "$FORCE_NO_SUDO" = "yes" ] || [ "$(whoami)" = "root" ]
	then
		echo "Using docker to run test-drive (I am root)"
		docker="docker"
	else
		echo "Using docker to run test-drive (via sudo)"
		docker="sudo docker"
	fi
fi

BUILD_FROM="${1:-debian:bullseye}"
tagname=$(echo "$BUILD_FROM" | sed 's/[:\/]/-/g')
case "$BUILD_FROM" in
	'debian:'*|'debian/eol:'*)
		dockerfile="Dockerfile-Debian"
		;;
	ubuntu:*)
		dockerfile="Dockerfile-Debian"
		;;
	fedora:* | centos:* | redhat/*:* | rockylinux:* )
		dockerfile="Dockerfile-Redhat"
		;;
	archlinux:*)
		dockerfile="Dockerfile-Archlinux"
		;;
	*)
		echo "Please provide distro name"
		echo " - debian:bookworm"
		echo " - debian:buster"
		echo " - debian/eol:stretch"
		echo " - ubuntu:xenial"
		echo " - centos:8"
		echo " - fedora:34"
		echo " - archlinux:latest"
		exit 1
		;;
esac

# script location
whereiam="$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )"

# the location of the current source to be packaged
srcdir="$( cd "${whereiam}/../.." >/dev/null 2>&1 && pwd )"

# the temporary directory which will be shared as a docker volume
tmpdir="$XDG_RUNTIME_DIR/shell-pack-test-drive-$tagname"
mkdir -p "$tmpdir"
download_file="korkman-shell-pack-latest.tar.gz"

# test if image is present, otherwise force build
if [ "$($docker images --quiet "shell-pack:test-drive-${tagname}")" = "" ]
then
	do_build="yes"
fi

# build
if [ "$do_build" = "yes" ]
then
	#echo "${whereiam}"
	#echo "${tagname}"
	cache_arg=""
	[ "$build_uncached" = "yes" ] && cache_arg="--no-cache "
	$docker build \
		$cache_arg --build-arg "BUILD_FROM=docker.io/$BUILD_FROM" \
		-t "shell-pack:test-drive-${tagname}" -f "${dockerfile}" .
fi

# package src
# exclude unnecessary .git and binaries potentially unsuitable for platform
# also exclude dool.d to simulate first use experience (clear download cache for this)
echo "Package ${srcdir}"
(cd "${srcdir}" && tar \
	'--exclude=.git' \
	'--exclude=rg' \
	'--exclude=fzf' \
	'--exclude=sk' \
	'--exclude=dool.d' \
	-czf "${tmpdir}/${download_file}" \
".")

echo "Copy get.sh"
cp -f "$srcdir/get.sh" "$tmpdir/get.sh"

echo "Create caching directory"
cachedir="$HOME/.cache/shell-pack-devel/docker/$tagname"
mkdir -p "$cachedir"

echo "Copy over cached rg, fzf, dool.d … if present"
if [ "$USE_CACHED_DOWNLOADS" = "yes" ]
then
	if [ -e "$cachedir/rg" ]
	then
		echo "found cached rg"
		cp "$cachedir/rg" "$tmpdir/rg"
	fi
	if [ -e "$cachedir/fzf" ]
	then
		echo "found cached fzf"
		cp "$cachedir/fzf" "$tmpdir/fzf"
	fi
	if [ -e "$cachedir/sk" ]
	then
		echo "found cached sk"
		cp "$cachedir/sk" "$tmpdir/sk"
	fi
	if [ -e "$cachedir/dool.d" ]
	then
		echo "found cached dool.d"
		cp -a "$cachedir/dool.d" "$tmpdir/"
	fi
fi

echo "Run $docker"
$docker run --rm \
-e AUTOSTART="$AUTOSTART" \
-e TERM="$TERM" \
--hostname "test-${tagname}" \
--volume "$tmpdir:/root/Downloads:rw" \
--interactive \
--tty "shell-pack:test-drive-${tagname}"

echo "Save downloaded rg, fzf, dool.d, … to cache"
if [ -e "$tmpdir/rg" ] && [ ! -e "$cachedir/rg" ]
then
	echo "Caching downloaded rg ..."
	cp "$tmpdir/rg" "$cachedir/rg"
fi
if [ -e "$tmpdir/fzf" ] && [ ! -e "$cachedir/fzf" ]
then
	echo "Caching downloaded fzf ..."
	cp "$tmpdir/fzf" "$cachedir/fzf"
fi
if [ -e "$tmpdir/sk" ] && [ ! -e "$cachedir/sk" ]
then
	echo "Caching downloaded sk ..."
	cp "$tmpdir/sk" "$cachedir/sk"
fi
if [ -e "$tmpdir/dool.d" ] && [ ! -e "$cachedir/dool.d" ]
then
	echo "Caching downloaded dool.d ..."
	cp -r "$tmpdir/dool.d" "$cachedir/"
fi

# clean-up
rm -rf "$tmpdir"

exit
}